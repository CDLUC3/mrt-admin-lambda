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
      endpoint = "scandelete/#{maintid}?t=json"
    else
      return {message: "No action"}.to_json
    end

    begin
      qjson = HttpPostJson.new(get_replic_server, endpoint)
      return { message: "Status #{qjson.status} for #{endpoint}" }.to_json unless qjson.status == 200
      return qjson.body unless qjson.body.empty?
      { message: "No response for #{endpoint}" }.to_json
    rescue => e
      puts(e.message)
      puts(e.backtrace)
      { error: "#{e.message} for #{endpoint}" }.to_json
    end

  end

end
