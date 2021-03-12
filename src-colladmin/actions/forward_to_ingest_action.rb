require 'httpclient'
require_relative 'action'

class ForwardToIngestAction < AdminAction
  def initialize(config, path, myparams, endpoint)
    super(config, path, myparams)
    @endpoint = endpoint
  end

  def hasTable
    false
  end

  def convertJsonToTable(body)
    return body unless hasTable
    {
      format: 'report',
      title: get_title,
      headers: table_headers,
      types: table_types,
      data: table_rows(body),
      filter_col: nil,
      group_col: nil,
      show_grand_total: false,
      merritt_path: @merritt_path,
      alternative_queries: get_alternative_queries,
      iterate: false
    }.to_json
  end

  def get_data_for_endpoint(endpoint)
    url = "#{get_ingest_server}#{endpoint}"
    cli = HTTPClient.new
    resp = cli.get(url, {}, {"Accept": "application/json"})
    resp
  end

  def get_data
    begin
      resp = get_data_for_endpoint(@endpoint)
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
  def get_alternative_queries
    []
  end

end
