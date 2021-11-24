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
    coll = @myparams.fetch("coll", "0").to_i
    if @path == "storage-add-node-for-collection"
      return MerrittQuery.new(@config).run_update(
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
    end
  end

end
