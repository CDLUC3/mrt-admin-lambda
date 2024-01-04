# frozen_string_literal: true

require_relative 'action'
require_relative '../lib/queue'
require_relative '../lib/http_get_json'

# Collection Admin Task class - see config/actions.yml for description
class ForwardToIngestAction < AdminAction
  def initialize(config, action, path, myparams, endpoint)
    super(config, action, path, myparams)
    @endpoint = endpoint
  end

  def get_body
    qjson = HttpGetJson.new(get_ingest_server, @endpoint)
    return { message: "Status #{qjson.status} for #{@endpoint}" }.to_json unless qjson.status == 200

    qjson.body unless qjson.body.empty?
  end

  def perform_action
    body = get_body
    return convert_json_to_table(body) unless body.empty?

    { message: "No response for #{@endpoint}" }.to_json
  rescue StandardError => e
    log(e.message)
    log(e.backtrace)
    { error: "#{e.message} for #{@endpoint}" }.to_json
  end

  def get_ingest_server
    @config.fetch('ingest-services', '').split(',').first
  end
end
