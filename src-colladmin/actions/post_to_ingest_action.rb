# frozen_string_literal: true

require_relative 'action'
require_relative 'forward_to_ingest_action'
require_relative '../lib/http_post_json'

# Collection Admin Task class - see config/actions.yml for description
class PostToIngestAction < ForwardToIngestAction
  def initialize(config, action, path, myparams, endpoint)
    @reload_path = myparams.fetch('reload_path', '')
    super
  end

  def perform_action
    qjson = HttpPostJson.new(get_ingest_server, @endpoint)
    return { message: "Status #{qjson.status} for #{@endpoint}" }.to_json unless qjson.status == 200

    unless @reload_path.empty?
      return {
        redirect_location: "/web/collIndex.html?path=#{@reload_path}"
      }.to_json
    end
    return convert_json_to_table(qjson.body) unless qjson.body.empty?

    { message: "No response for #{@endpoint}" }.to_json
  rescue StandardError => e
    log(e.message)
    log(e.backtrace)
    { error: "#{e.message} for #{@endpoint}" }.to_json
  end

  def get_title
    'Ingest State'
  end

  def table_headers
    %w[
      Key
      Value
    ]
  end

  def table_types
    [
      '',
      ''
    ]
  end

  def table_rows(body)
    data = JSON.parse(body)
    data = data.fetch('ing:ingestServiceState', {})
    rows = []
    data.each_key do |k|
      if k == 'ing:storageInstances'
        obj = data.fetch('ing:storageInstances', {})
        obj = {} if obj == ''
        rows.append([k, obj.fetch('ing:storageURL', {}).fetch('ing:uRL', '')])
      else
        rows.append([k, data.fetch(k, '')])
      end
    end
    rows
  end

  def has_table
    true
  end
end
