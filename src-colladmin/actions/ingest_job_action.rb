require_relative 'action'
require_relative 'forward_to_ingest_action'

class IngestJobAction < ForwardToIngestAction
  def initialize(config, path, myparams)
    @batch = myparams.fetch('batch', '')
    @job = myparams.fetch('job', '')
    super(config, path, myparams, "admin/jid-erc/#{@batch}/#{@job}")
  end

  def get_title
    "Ingest Job #{@job}"
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
    data = data.fetch('fil:jobFileState', {})
    data = data.fetch('fil:jobFile', {})
    rows = []
    data.keys.each do |k|
      rows.append([k, data.fetch(k, "")])
    end
    rows
  end

  def hasTable
    true
  end

end
