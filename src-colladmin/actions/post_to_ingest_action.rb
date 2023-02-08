require_relative 'action'
require_relative 'forward_to_ingest_action'
require_relative '../lib/http_post_json'

class PostToIngestAction < ForwardToIngestAction
  def initialize(config, action, path, myparams, endpoint)
    @reload_path = myparams.fetch("reload_path", "")
    super(config, action, path, myparams, endpoint)
  end

  def perform_action
    begin
      qjson = HttpPostJson.new(get_ingest_server, @endpoint)
      return { message: "Status #{qjson.status} for #{@endpoint}" }.to_json unless qjson.status == 200
      unless @reload_path.empty?
        return {
          redirect_location: "/web/collIndex.html?path=#{@reload_path}"
        }.to_json
      end
      return convertJsonToTable(qjson.body) unless qjson.body.empty?
      { message: "No response for #{@endpoint}" }.to_json
    rescue => e
      puts(e.message)
      puts(e.backtrace)
      { error: "#{e.message} for #{@endpoint}" }.to_json
    end
  end

  def get_title
    "Ingest State"
  end

  def table_headers
    [
      'Key',
      'Value'
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
    data.keys.each do |k|
      v = 
      if k == 'ing:storageInstances' 
        obj = data.fetch("ing:storageInstances", {})
        obj = {} if obj == ""
        rows.append([k, obj.fetch("ing:storageURL", {}).fetch("ing:uRL", "")])
      else
        rows.append([k, data.fetch(k, "")])
      end
    end
    rows
  end

  def hasTable
    true
  end

end
