require_relative 'action'
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
      'Job', 
      'Date'
    ]
  end

  def table_types
    [
      'qjob',
      ''
    ]
  end

  def table_rows(body)
    JobList.new(body).to_table
  end

  def hasTable
    true
  end

end
