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
      'Batch Manifest',
      'Job',
      'Comment'
    ]
  end

  def table_types
    [
      '',
      'qjob',
      ''
    ]
  end

  def table_rows(body)
    data = JSON.parse(body)
    data = data.fetch('fil:batchFileState', {})
    bm  = data.fetch("fil:batchManifest", "")
    jf  = data.fetch("fil:jobFile", {})
    jbf = jf.fetch("fil:batchFile", {})
    jbff = jbf.fetch("fil:file", "")

    rows = []
    rows.append([bm, "#{@batch}/#{jbff}", "how do mult jobs get represented"])
    rows
  end

  def hasTable
    true
  end

end
