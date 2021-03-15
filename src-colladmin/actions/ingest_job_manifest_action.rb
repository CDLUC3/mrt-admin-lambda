require_relative 'action'
require_relative 'forward_to_ingest_action'

class IngestJobManifestAction < ForwardToIngestAction
  def initialize(config, path, myparams)
    @batch = myparams.fetch('batch', '')
    @job = myparams.fetch('job', '')
    super(config, path, myparams, "admin/jid-manifest/#{@batch}/#{@job}")
  end

  def get_title
    "Ingest Job Manifest #{@job}"
  end

  def table_headers
    JobManifestEntry.table_headers
  end

  def table_types
    JobManifestEntry.table_types
  end

  def table_rows(body)
    JobManifest.new(body).to_table
  end

  def hasTable
    true
  end

  def get_alternative_queries
    [
      {
        label: 'Job Metadata', 
        url: "path=job&batch=#{@batch}&job=#{@job}"
      }
    ]
  end

end
