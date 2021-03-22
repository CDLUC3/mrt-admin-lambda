require_relative 'action'
require_relative 'forward_to_ingest_action'

class IngestJobFilesAction < ForwardToIngestAction
  def initialize(config, path, myparams)
    @batch = myparams.fetch('batch', '')
    @job = myparams.fetch('job', '')
    super(config, path, myparams, "admin/jid-file/#{@batch}/#{@job}")
  end

  def get_title
    "Ingest Job Files #{@job}"
  end

  def table_headers
    JobFile.table_headers
  end

  def table_types
    JobFile.table_types
  end

  def table_rows(body)
    JobFiles.new(body).to_table
  end

  def hasTable
    true
  end

  def get_alternative_queries
    [
      {
        label: 'Job Metadata', 
        url: "path=job&batch=#{@batch}&job=#{@job}"
      },
      {
        label: 'Job Manifest', 
        url: "path=manifest&batch=#{@batch}&job=#{@job}"
      },
    ]
  end

end
