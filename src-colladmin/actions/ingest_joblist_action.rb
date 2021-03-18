require_relative 'action'
require_relative 'forward_to_ingest_action'
require_relative '../lib/queue'

class IngestJoblistAction < ForwardToIngestAction
  def initialize(config, path, myparams, endpoint)
    super(config, path, myparams, endpoint)
  end

  def get_title
    "Joblist"
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
