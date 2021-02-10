require 'httpclient'
require_relative 'action'

class ForwardToIngestAction < AdminAction
  def initialize(config, path, myparams, endpoint)
    super(config, path, myparams)
    @endpoint = endpoint
  end

  def convertJsonToTable(body)
    body
  end

  def get_data
    cli = HTTPClient.new
    url = "#{get_ingest_server}#{@endpoint}"
    begin
      resp = cli.get(url, {}, {"Accept": "application/json"})
      return { message: "Status #{resp.status} for #{@endpoint}" }.to_json unless resp.status == 200
      return convertJsonToTable(resp.body) unless resp.body.empty?
      { message: "No response for #{@endpoint}" }.to_json
    rescue => e
      { error: "#{e.message} for #{@endpoint}" }.to_json
    end
  end

  def get_ingest_server
    @config.fetch('ingest-services', '').split(',').first
  end

end
