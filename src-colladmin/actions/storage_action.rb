require 'httpclient'
require 'cgi'
require_relative 'action'
require_relative 'forward_to_ingest_action'
require_relative '../lib/profile'
require_relative '../lib/admin_objects'
require_relative '../lib/storage_nodes'
require_relative '../lib/merritt_query'

class StorageAction < AdminAction
  def initialize(config, path, myparams)
    super(config, path, myparams)
  end

  def get_title
    "Storage Action: #{@path}"
  end

  def perform_action
    objid = @myparams.fetch("objid", "0").to_i
    nodeid = @myparams.fetch("nodeid", "0").to_i

    if @path == "storage-force-audit-for-object"
      return MerrittQuery.new(@config).run_update(
        %{
          update 
            inv_audits
          set
            verified = null
          where 
            inv_object_id = ?
          and
            inv_node_id = ?
        }, 
        [objid, nodeid],
        "Audit reset for object"
      ).to_json
    end
    if @path == "storage-rerun-audit-for-object"
      return MerrittQuery.new(@config).run_update(
        %{
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
        }, 
        [objid, nodeid],
        "Audit reset for object"
      ).to_json
    end
    if @path == "storage-force-replic-for-object"
      return MerrittQuery.new(@config).run_update(
        %{
          update 
            inv_nodes_inv_objects inio
          set
            replicated = null
          where 
            inv_object_id = ?
          and
            role = 'primary'
        }, 
        [objid],
        "Replication triggered for object"
      ).to_json
    end
    if @path == "storage-clear-audit-batch"
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
            verified < date_add(now(), INTERVAL -1 DAY)
        }, 
        [],
        "Audit Batches Cleared"
      ).to_json
    end

    nodenum = @myparams.fetch("nodenum", "0").to_i
    if @path == "storage-add-node-for-collection"
      coll = @myparams.fetch("coll", "0").to_i
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
        "Node added to collection"
      ).to_json

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
        "Replication status reset for all objects in the collection"
      ).to_json
      return res
    end

    ark = @myparams.fetch("ark", "")
    if @path == "storage-get-manifest"
      srvc = get_storage_service
      endpoint = "/manifest/#{nodenum}/#{CGI.escape(ark)}"
      return "<message>Storage service undefined</message>" if srvc.empty?
      return "<message>Empty Ark</message>"if ark.empty?

      begin
        qxml = HttpGetXml.new(srvc, endpoint)
        return "<message>Status #{qjson.status} for #{endpoint}</message>" unless qxml.status == 200
        return qxml.body
        return "<message>No response for #{endpoint}</message>"
      rescue => e
        puts(e.message)
        puts(e.backtrace)
        return "<message>Error #{e.message} for #{endpoint}</message>"
      end
  
    end

    if @path == "storage-get-augmented-manifest"
    end

    if @path == "storage-get-ingest-checkm"
      ver = @myparams.fetch("ver", "1").to_i
      srvc = get_storage_service
      endpoint = "/ingestlink/#{nodenum}/#{CGI.escape(ark)}/#{ver}"
      return "<message>Storage service undefined</message>" if srvc.empty?
      return "<message>Empty Ark</message>"if ark.empty?

      begin
        qxml = HttpGetXml.new(srvc, endpoint)
        return "<message>Status #{qjson.status} for #{endpoint}</message>" unless qxml.status == 200
        return qxml.body
        return "<message>No response for #{endpoint}</message>"
      rescue => e
        puts(e.message)
        puts(e.backtrace)
        return "<message>Error #{e.message} for #{endpoint}</message>"
      end
    end

    if @path == "storage-clear-scan-entries"
    end

    if @path == "storage-rebuild-inventory"
      # INV DELETE object/ARK
      srvc = get_inventory_service
      endpoint = "/object/#{CGI.escape(ark)}"
      return {message: "Inventory service undefined"}.to_json if srvc.empty?
      return {message: "Empty Ark"}.to_json if ark.empty?

      qjson = HttpDeleteJson.new(srvc, endpoint)
      return {message: "Inventory delete failed"}.to_json if qjson.status != 200
      
      endpoint = "/add"
      data = {
        "url" => "#{get_storage_service}/manifest/#{nodenum}/#{CGI.escape(ark)}",
        "responseForm" => "json"
      }

      qjson = HttpPostMultipartJson.new(srvc, endpoint, data)
      return {message: "Inventory recreate failed"}.to_json if qjson.status != 200

      {message: "Inventory Delete and Recreate Successful"}.to_json
    end

    # if @path == "storage-update-manifest"
    # end

  end

  def get_storage_service
    @config.fetch('storage-service', '')
  end

  def get_inventory_service
    @config.fetch('inventory-service', '')
  end

end
