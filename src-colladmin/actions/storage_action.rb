# frozen_string_literal: true

require 'httpclient'
require 'cgi'
require_relative 'action'
require_relative 'forward_to_ingest_action'
require_relative '../lib/profile'
require_relative '../lib/admin_objects'
require_relative '../lib/storage_nodes'
require_relative '../lib/merritt_query'
require_relative '../lib/audit_info'

# Collection Admin Task class - see config/actions.yml for description
class StorageAction < AdminAction
  def get_title
    "Storage Action: #{@path}"
  end

  def perform_action
    objid = @myparams.fetch('objid', '0').to_i
    nodeid = @myparams.fetch('nodeid', '0').to_i

    if @path == 'storage-force-audit-for-object'
      return MerrittQuery.new(@config).run_update(
        %(
          update
            inv_audits
          set
            verified = null
          where
            inv_object_id = ?
          and
            inv_node_id = ?
        ),
        [objid, nodeid],
        'Audit reset for object'
      ).to_json
    end
    if @path == 'storage-rerun-audit-for-object'
      return MerrittQuery.new(@config).run_update(
        %(
          update
            inv_audits
          set
            verified = null
          where
            inv_object_id = ?
          and
            inv_node_id = ?
          and
            status != 'verified'
        ),
        [objid, nodeid],
        'Audit reset for object'
      ).to_json
    end
    if @path == 'storage-force-replic-for-object'
      return MerrittQuery.new(@config).run_update(
        %(
          update
            inv_nodes_inv_objects inio
          set
            replicated = null
          where
            inv_object_id = ?
          and
            role = 'primary'
        ),
        [objid],
        'Replication triggered for object'
      ).to_json
    end
    if @path == 'storage-clear-audit-batch'
      hours = @myparams.fetch('hours', '24').to_i
      hours = 1 if hours < 1
      return MerrittQuery.new(@config).run_update(
        %{
          UPDATE
            inv_audits
          SET
            status='unknown',
            verified=null
          WHERE
            status='processing'
          AND
            ifnull(verified, '1970-01-01') < date_add(now(), INTERVAL -#{hours} HOUR)
        },
        [],
        'Audit Batches Cleared'
      ).to_json
    end
    if @path == 'storage-retry-audit-status'
      status = @myparams.fetch('status', '')
      status = '' if status == 'verified'
      return MerrittQuery.new(@config).run_update(
        %(
          UPDATE
            inv_audits
          SET
            status='unknown',
            verified=null
          WHERE
            status = ?
        ),
        [status],
        'Audit Retries Set'
      ).to_json
    end

    nodenum = @myparams.fetch('nodenum', '0').to_i
    if @path == 'storage-add-node-for-collection'
      coll = @myparams.fetch('coll', '0').to_i
      res = MerrittQuery.new(@config).run_update(
        %{
          INSERT INTO
            inv_collections_inv_nodes(
              inv_collection_id,
              inv_node_id
            )
          SELECT
            ?,
            (
              select
                id
              from
                inv_nodes
              where
                number = ?
            )
        },
        [coll, nodenum],
        'Node added to collection'
      ).to_json

      trigger_repl = true
      if trigger_repl
        MerrittQuery.new(@config).run_update(
          %{
            update
              inv_nodes_inv_objects inio
            set
              replicated = null
            where
              role = 'primary'
            and exists (
              select
                1
              from
                inv_collections_inv_objects icio
              where
                icio.inv_collection_id = ?
              and
                icio.inv_object_id = inio.inv_object_id
            )
          },
          [coll],
          'Replication status reset for all objects in the collection'
        ).to_json
      end
      return res
    elsif @path == 'storage-del-node-for-collection'
      coll = @myparams.fetch('coll', '0').to_i
      res = MerrittQuery.new(@config).run_update(
        %{
          DELETE FROM
            inv_collections_inv_nodes
          WHERE
            inv_collection_id = ?
          AND
            inv_node_id = (
              select
                id
              from
                inv_nodes
              where
                number = ?
            )
        },
        [coll, nodenum],
        'Node removed from collection config'
      ).to_json
      return res
    end

    ark = @myparams.fetch('ark', '')
    if @path == 'storage-get-manifest'
      srvc = get_storage_service
      endpoint = "/manifest/#{nodenum}/#{CGI.escape(ark)}"
      return '<message>Storage service undefined</message>' if srvc.empty?
      return '<message>Empty Ark</message>' if ark.empty?

      begin
        qxml = HttpGetXml.new(srvc, endpoint)
        return "<message>Status #{qxml.status} for #{endpoint}</message>" unless qxml.status == 200
        if qxml.body.length > 5_000_000
          return "<message>Manifest is too large to download:  use curl: #{srvc}#{endpoint}</message>"
        end

        return qxml.body
      rescue StandardError => e
        log(e.message)
        log(e.backtrace)
        return "<message>Error #{e.message}, try curl:  #{srvc}#{endpoint}</message>"
      end

    end

    if @path == 'storage-get-ingest-checkm'
      ver = @myparams.fetch('ver', '1').to_i
      srvc = get_storage_service
      endpoint = "/ingestlink/#{nodenum}/#{CGI.escape(ark)}/#{ver}?presign=true"
      return '<message>Storage service undefined</message>' if srvc.empty?
      return '<message>Empty Ark</message>' if ark.empty?

      begin
        qxml = HttpGetXml.new(srvc, endpoint)
        return "<message>Status #{qxml.status} for #{endpoint}</message>" unless qxml.status == 200
        if qxml.body.length > 5_000_000
          return "<message>Manifest is too large to download:  use curl: #{srvc}#{endpoint}</message>"
        end

        return qxml.body
      rescue StandardError => e
        log(e.message)
        log(e.backtrace)
        return "<message>Error #{e.message}, try curl:  #{srvc}#{endpoint}</message>"
      end
    end

    if @path == 'storage-clear-scan-entries'
      return { message: "Invalid ark: #{ark}" }.to_json unless ark =~ %r{^ark:/.+/.+}

      res = MerrittQuery.new(@config).run_update(
        %{
          DELETE FROM
            inv_storage_maints
          WHERE
            s3key like concat(?,'%')
          AND
            maint_status != 'removed'
        },
        [ark],
        "Scan records deleted for #{ark}"
      ).to_json
      return res
    end

    if @path == 'storage-rebuild-inventory'
      # INV DELETE object/ARK
      srvc = get_inventory_service
      endpoint = "/object/#{CGI.escape(ark)}"
      return { message: 'Inventory service undefined' }.to_json if srvc.empty?
      return { message: 'Empty Ark' }.to_json if ark.empty?

      qjson = HttpDeleteJson.new(srvc, endpoint)
      return { message: 'Inventory delete failed' }.to_json if qjson.status != 200

      endpoint = '/add'
      data = {
        'url' => "#{get_storage_service}/manifest/#{nodenum}/#{CGI.escape(ark)}",
        'responseForm' => 'json'
      }

      qjson = HttpPostMultipartJson.new(srvc, endpoint, data)
      return { message: 'Inventory recreate failed' }.to_json if qjson.status != 200

      { message: 'Inventory Delete and Recreate Successful' }.to_json
    end

    # if @path == "storage-update-manifest"
    # end
    return unless @path == 'storage-set-flag'

    op = @myparams.fetch('op', 'set')
    op = 'state' unless %w[set clear state].include?(op)
    qobj = @myparams.fetch('object', '')
    srvc = get_access_service
    endpoint = "/flag/#{op}/access/#{qobj}?t=json"
    qjson = HttpPostJson.new(srvc, endpoint)
    return message_as_table('Access ZK flag set failed').to_json if qjson.status != 200

    ts = JSON.parse(qjson.body).fetch('tok:zooTokenState', {})
    tss = ts.fetch('tok:tokenStatus', '')
    tso = ts.fetch('tok:zooFlagPath', 'na')
    reload_path = @myparams.fetch('reload_path', '')
    unless reload_path.empty?
      return {
        redirect_location: "/web/collIndex.html?path=#{reload_path}"
      }.to_json
    end
    message_as_table("Token result: #{tso}=#{tss}").to_json
  end

  def get_storage_service
    @config.fetch('storage-service', '')
  end

  def get_access_service
    @config.fetch('access-service', '')
  end

  def get_inventory_service
    @config.fetch('inventory-service', '')
  end
end
