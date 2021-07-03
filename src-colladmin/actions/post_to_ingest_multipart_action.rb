require_relative 'action'
require_relative 'forward_to_ingest_action'
require_relative '../lib/http_post_multipart_json'

class PostToIngestMultipartAction < ForwardToIngestAction
  def initialize(config, path, myparams, endpoint)
    super(config, path, myparams, endpoint)
  end

  def get_data
    begin
      qjson = HttpPostMultipartJson.new(get_ingest_server, @endpoint, @myparams)

      raise qjson.body if (qjson.status != 200 or qjson.body.include?("INVALID_CONFIGURATION"))
      return convertJsonToTable(qjson.body) unless qjson.body.empty?
      { message: "No response for #{@endpoint}" }.to_json
    rescue => e
      # Bubble error up
      raise e.message
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
    false
  end

end
