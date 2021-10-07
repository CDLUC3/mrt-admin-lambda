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
      MerrittQuery.new(@config).run_update(
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
      #return LambdaBase.jsredirect("#{LambdaBase.colladmin_root_url}/web/storeObjectNodes.html?id=#{objid}")
    end
    if @path == "storage-rerun-audit-for-object"
      MerrittQuery.new(@config).run_update(
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
      #return LambdaBase.jsredirect("#{LambdaBase.colladmin_root_url}/web/storeObjectNodes.html?id=#{objid}")
    end
    if @path == "storage-force-replic-for-object"
      MerrittQuery.new(@config).run_update(
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
      #return LambdaBase.jsredirect("#{LambdaBase.colladmin_root_url}/web/storeObjects.html?mode=id&objlist=#{objid}")
    end
  end

end
