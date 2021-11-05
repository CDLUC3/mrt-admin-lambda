require 'httpclient'
require 'cgi'
require_relative 'action'
require_relative 'forward_to_ingest_action'
require_relative '../lib/profile'
require_relative '../lib/admin_objects'
require_relative '../lib/storage_nodes'
require_relative '../lib/merritt_query'

class ReplicationAction < AdminAction
  def initialize(config, path, myparams)
    super(config, path, myparams)
  end

  def get_replic_server
    @config.fetch('replic-service', '')
  end

  def perform_action
    endpoint = ''
    post = true
    if @path == "storage-scan-node"
      nodeid = @myparams.fetch("nodenum", "0").to_i
      endpoint = "scan/start/#{nodeid}?t=json"
      # determine if the node must be traversed via a keylist file (sdsc)
      keylist = ''
      @config.fetch("scan-use-keylist", []).each do |c|
        keylist = c['keylist'] if c['node'].to_i == nodeid
      end 
      endpoint = "#{endpoint}&keylist=#{keylist}" unless keylist.empty?
    elsif @path == "storage-cancel-all-scans" 
      endpoint = 'scan/allow/false?t=json'
    elsif @path == "storage-allow-all-scans" 
      endpoint = 'scan/allow/true?t=json'
    elsif @path == "storage-cancel-scan-node" 
      scanid = @myparams.fetch("scanid", "0").to_i
      endpoint = "scan/cancel/#{scanid}?t=json"
    elsif @path == "storage-resume-scan-node" 
      scanid = @myparams.fetch("scanid", "0").to_i
      endpoint = "scan/restart/#{scanid}?t=json"
    elsif @path == "storage-delete-node-key" 
      maintid = @myparams.fetch("maintid", "0").to_i
      return MerrittQuery.new(@config).run_update(
        %{
          UPDATE 
            inv_storage_maints
          SET 
            maint_status='delete'
          WHERE 
            id = ?
        }, 
        [maintid],
        "Maint Status set to delete"
      ).to_json
      # TODO - trigger the following with method=DELETE
      # endpoint = "scandelete/#{maintid}?t=json"
    elsif @path == "storage-hold-node-key" 
      maintid = @myparams.fetch("maintid", "0").to_i
      return MerrittQuery.new(@config).run_update(
        %{
          UPDATE 
            inv_storage_maints
          SET 
            maint_status='hold'
          WHERE 
            id = ?
        }, 
        [maintid],
        "Maint Status set to hold"
      ).to_json
    elsif @path == "storage-review-node-key" 
      maintid = @myparams.fetch("maintid", "0").to_i
      return MerrittQuery.new(@config).run_update(
        %{
          UPDATE 
            inv_storage_maints
          SET 
            maint_status='review'
          WHERE 
            id = ?
        }, 
        [maintid],
        "Maint Status set to review"
      ).to_json
    elsif @path == "replication-state" 
      endpoint = 'state?t=json'
      post = false
    else
      return {message: "No action"}.to_json
    end

    begin
      qjson = post ? HttpPostJson.new(get_replic_server, endpoint) : HttpGetJson.new(get_replic_server, endpoint)
      return { message: "Status #{qjson.status} for #{endpoint}" }.to_json unless qjson.status == 200
      return parseReplicResponse(qjson.body).to_json unless qjson.body.empty?
      { message: "No response for #{endpoint}" }.to_json
    rescue => e
      puts(e.message)
      puts(e.backtrace)
      { error: "#{e.message} for #{endpoint}" }.to_json
    end

  end

  def parseReplicResponse(json) 
    resp = JSON.parse(json)
    if @path == "storage-cancel-scan-node" || @path == "storage-resume-scan-node" || @path == "storage-scan-node" 
    {
      message: resp.fetch("repscan:invStorageScan", {}).fetch("repscan:scanStatus", "na")
    }
    elsif @path == "storage-cancel-all-scans" || @path == "storage-allow-all-scans" || @path == "replication-state"
    {
      message: "Scan Allowed: #{resp.fetch("repsvc:replicationServiceState", {}).fetch("repsvc:allowScan", "na")}"
    }
    else
      resp
    end
  end

end
