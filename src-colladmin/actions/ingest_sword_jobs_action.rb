require_relative 'action'
require_relative 'forward_to_ingest_action'
require_relative '../lib/queue'

class IngestSwordJobsAction < ForwardToIngestAction
  def initialize(config, path, myparams)
    super(config, path, myparams, "admin/bid/JOB_ONLY")
  end

  def get_title
    "Sword Jobs"
  end

  def table_headers
    [
      'Job'
    ]
  end

  def table_types
    [
      'qjob'
    ]
  end

  def table_rows(body)
    queueList = JobList.new(body)
    queueList.to_table
  end

  def hasTable
    true
  end

end
