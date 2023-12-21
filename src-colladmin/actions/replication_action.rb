# frozen_string_literal: true

require 'httpclient'
require 'cgi'
require_relative 'action'
require_relative 'forward_to_ingest_action'
require_relative '../lib/profile'
require_relative '../lib/admin_objects'
require_relative '../lib/storage_nodes'
require_relative '../lib/merritt_query'
require_relative '../lib/http_delete_json'

class ReplicationAction < AdminAction
  def get_replic_server
    @config.fetch('replic-service', '')
  end

  def update_maint
    %(
      UPDATE
        inv_storage_maints
      SET
        maint_status= ?
      WHERE
        maint_status != 'removed'
      and
        id = ?
    )
  end

  def maintidlist_params(status)
    maintidlist = [status]
    @myparams.fetch('maintidlist', '').split(',').each do |id|
      maintidlist.append(id.to_i)
    end
    maintidlist
  end

  def maintidlist_placeholders
    placeholders = []
    @myparams.fetch('maintidlist', '').split(',').each do |_id|
      placeholders.append('?')
    end
    placeholders.join(',')
  end

  def maintidlist_update
    %{
      UPDATE
        inv_storage_maints
      SET
        maint_status = ?
      WHERE
        maint_status != 'removed'
      and
        id in (#{maintidlist_placeholders})
    }
  end

  def perform_action
    endpoint = ''
    method = :post
    case @path
    when 'storage-scan-node'
      nodeid = @myparams.fetch('nodenum', '0').to_i
      endpoint = "scan/start/#{nodeid}?t=json"
      # determine if the node must be traversed via a keylist file (sdsc)
      keylist = ''
      @config.fetch('scan-use-keylist', []).each do |c|
        keylist = c['keylist'] if c['node'].to_i == nodeid
      end
      endpoint = "#{endpoint}&keylist=#{keylist}" unless keylist.empty?
    when 'storage-cancel-all-scans'
      endpoint = 'scan/allow/false?t=json'
    when 'storage-allow-all-scans'
      endpoint = 'scan/allow/true?t=json'
    when 'storage-cancel-scan-node'
      scanid = @myparams.fetch('scanid', '0').to_i
      endpoint = "scan/cancel/#{scanid}?t=json"
    when 'storage-resume-scan-node'
      scanid = @myparams.fetch('scanid', '0').to_i
      endpoint = "scan/restart/#{scanid}?t=json"
    when 'storage-delete-node-key'
      maintid = @myparams.fetch('maintid', '0').to_i
      return MerrittQuery.new(@config).run_update(
        update_maint,
        ['delete', maintid],
        'Maint Status set to delete'
      ).to_json
    when 'storage-delete-node-page'
      return MerrittQuery.new(@config).run_update(
        maintidlist_update,
        maintidlist_params('delete'),
        'Maint Status set to delete for block of items'
      ).to_json
    when 'storage-perform-delete-node-key'
      maintid = @myparams.fetch('maintid', '0').to_i
      method = :delete
      endpoint = "scandelete/#{maintid}?t=json"
    when 'storage-perform-delete-node-batch'
      nodenum = @myparams.fetch('nodenum', '0').to_i
      method = :delete
      endpoint = "scandelete-list/#{nodenum}?t=json"
    when 'storage-hold-node-key'
      maintid = @myparams.fetch('maintid', '0').to_i
      return MerrittQuery.new(@config).run_update(
        update_maint,
        ['hold', maintid],
        'Maint Status set to hold'
      ).to_json
    when 'storage-hold-node-page'
      return MerrittQuery.new(@config).run_update(
        maintidlist_update,
        maintidlist_params('hold'),
        'Maint Status set to hold for block of items'
      ).to_json
    when 'storage-review-node-key'
      maintid = @myparams.fetch('maintid', '0').to_i
      return MerrittQuery.new(@config).run_update(
        update_maint,
        ['review', maintid],
        'Maint Status set to review'
      ).to_json
    when 'storage-review-node-page'
      return MerrittQuery.new(@config).run_update(
        maintidlist_update,
        maintidlist_params('review'),
        'Maint Status set to review for block of items'
      ).to_json
    when 'storage-review-csv'
      nodenum = @myparams.fetch('nodenum', '0').to_i
      rev = ScanReview.new(@config, 'review')
      rev.process_resuts(
        rev.nodenum_query(nodenum, 1_000_000, 0)
      )
      key = "scan-review/#{nodenum}.csv"
      @s3_client.put_object({
        body: rev.to_csv,
        bucket: @s3bucket,
        key: "scan-review/#{nodenum}.csv",
        content_type: 'text/csv'
      })
      signer = Aws::S3::Presigner.new
      url, = signer.presigned_request(
        :get_object,
        bucket: @s3bucket,
        key: key
      )
      return {
        download_url: url,
        label: "Review List for #{nodenum}"
      }.to_json
    when 'replication-state'
      endpoint = 'state?t=json'
      method = :get
    when 'apply-review-changes'
      nodenum = @myparams.fetch('nodenum', '0').to_i
      count = 0
      JSON.parse(@myparams.fetch('changes', '[]')).each do |change|
        next unless change.length == 3

        maintid = change[0].to_i
        status = change[1]
        note = change[2]
        MerrittQuery.new(@config).run_update(
          %{
            update
              inv_storage_maints
            set
              maint_status = ?,
              note = ?
            where
              id = ?
            and
              maint_status != 'removed'
            and
              inv_node_id = (
                select
                  id
                from
                  inv_nodes
                where
                  number = ?
              )
          },
          [status, note, maintid, nodenum],
          'Maint Status updated'
        )
        count += 1
      end
      return { log: "#{count} review records updated" }.to_json
    when 'replic-delete-coll-batch-from-node'
      nodenum = @myparams.fetch('nodenum', '0').to_i
      coll = @myparams.fetch('coll', '0').to_i
      ids = []
      MerrittQuery.new(@config).run_query(
        %{
          SELECT
            o.ark
          from
            inv_objects o
          inner join
            inv_collections_inv_objects icio
          on
            o.id = icio.inv_object_id
          WHERE
            icio.inv_collection_id = ?
          AND exists (
            select
              1
            from
              inv_nodes_inv_objects inio
            WHERE
              inio.inv_node_id = (
                select id from inv_nodes where number = ?
              )
            and
              inio.inv_object_id = icio.inv_object_id
            and
              inio.role = 'secondary'
          )
          limit 50
        },
        [coll, nodenum]
      ).each do |r|
        endpoint = "delete/#{nodenum}/#{CGI.escape(r[0])}"
        puts endpoint
        begin
          qjson = HttpDeleteJson.new(get_replic_server, endpoint)
          puts qjson.status
          ids.push(r[0]) if qjson.status == 200
        rescue StandardError => e
          log(e.message)
          log(e.backtrace)
          return { error: "#{e.message} for #{endpoint}" }.to_json
        end
      end
      return {
        message: "#{ids.length} objects removed from node #{nodenum}."
      }.to_json
    else
      return { message: 'No action' }.to_json
    end

    begin
      qjson = nil
      qjson = if method == :post
                HttpPostJson.new(get_replic_server, endpoint)
              elsif method == :delete
                HttpDeleteJson.new(get_replic_server, endpoint)
              else
                HttpGetJson.new(get_replic_server, endpoint)
              end
      return { message: "Status #{qjson.status} for #{endpoint}" }.to_json unless qjson.status == 200
      return parseReplicResponse(qjson.body).to_json unless qjson.body.empty?

      { message: "No response for #{endpoint}" }.to_json
    rescue StandardError => e
      log(e.message)
      log(e.backtrace)
      { error: "#{e.message} for #{endpoint}" }.to_json
    end
  end

  def parseReplicResponse(json)
    resp = JSON.parse(json)
    case @path
    when 'storage-cancel-scan-node', 'storage-resume-scan-node', 'storage-scan-node'
      {
        message: resp.fetch('repscan:invStorageScan', {}).fetch('repscan:scanStatus', 'na')
      }
    when 'storage-perform-delete-node-batch'
      {
        message: resp.fetch('repscan:invStorageScan', {}).fetch('repscan:scanStatus', 'na')
      }
    when 'storage-cancel-all-scans', 'storage-allow-all-scans', 'replication-state'
      {
        message: "Scan Allowed: #{resp.fetch('repsvc:replicationServiceState', {}).fetch('repsvc:allowScan', 'na')}"
      }
    when 'storage-perform-delete-node-key'
      {
        message: "Node/Key State: #{resp.fetch('repmnt:invStorageMaint', {}).fetch('repmnt:maintStatus', 'na')}"
      }
    else
      resp
    end
  end
end
