require 'httpclient'
require_relative 'action'
require_relative 'forward_to_ingest_action'

class IngestStateAction < ForwardToIngestAction
  def initialize(config, path, myparams)
    super(config, path, myparams, 'state')
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
      v = data.fetch(k, "")
      if k == 'ing:storageInstances' 
        v = data.fetch("ing:storageInstances", {}).fetch("ing:storageURL", {}).fetch("ing:uRL", "")
      end
      rows.append([k, v])
    end
    rows
  end

  def hasTable
    true
  end

end
