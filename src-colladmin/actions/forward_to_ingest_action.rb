require_relative 'action'
require_relative '../lib/queue'
require_relative '../lib/http_get_json'

class ForwardToIngestAction < AdminAction
  def initialize(config, path, myparams, endpoint)
    super(config, path, myparams)
    @endpoint = endpoint
  end

  def get_body
    qjson = HttpGetJson.new(get_ingest_server, @endpoint)
    return { message: "Status #{qjson.status} for #{@endpoint}" }.to_json unless qjson.status == 200
    return qjson.body unless qjson.body.empty?
  end

  def perform_action
    begin
      body = get_body
      return convertJsonToTable(body) unless body.empty?
      { message: "No response for #{@endpoint}" }.to_json
    rescue => e
      puts(e.message)
      puts(e.backtrace)
      { error: "#{e.message} for #{@endpoint}" }.to_json
    end
  end

  def get_ingest_server
    @config.fetch('ingest-services', '').split(',').first
  end

 
end
