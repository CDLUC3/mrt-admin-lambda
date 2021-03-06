require_relative 'action'
require_relative 'forward_to_ingest_action'

class IngestBatchAction < ForwardToIngestAction
  def initialize(config, path, myparams)
    @batch = myparams.fetch('batch', '')
    super(config, path, myparams, "admin/bid/#{@batch}")
  end

  def get_title
    "Ingest Batch Detail"
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

  # {"fil:batchFileState":{"xmlns:fil":"http://uc3.cdlib.org/ontology/mrt/store/file","fil:batchManifest":"","fil:jobFile":{"fil:batchFile":{"fil:file":"jid-5c9542e8-eb95-4657-8066-f03b0509ab81"}}}}

  def table_rows(body)
    puts(body)
    data = JSON.parse(body)
    data = data.fetch('fil:batchFileState', {})
    rows = []
    data.keys.each do |k|
      v = 
      if k == 'ing:storageInstances' 
        rows.append([k, data.fetch("ing:storageInstances", {}).fetch("ing:storageURL", {}).fetch("ing:uRL", "")])
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
