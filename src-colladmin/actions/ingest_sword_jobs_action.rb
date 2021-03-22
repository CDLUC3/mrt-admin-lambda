require_relative 'action'
require_relative '../lib/queue'

class IngestSwordJobsAction < ForwardToIngestAction
  def initialize(config, path, myparams)
    @days = myparams.fetch("days", "7").to_i 
    @days = 7 if @days > 7
    super(config, path, myparams, "admin/bid/JOB_ONLY")
  end

  def get_title
    "Sword Jobs"
  end

  def table_headers
    Job.table_headers
  end

  def table_types
    Job.table_types
  end

  def table_rows(body)
    jlist = JobList.new(body)
    jlist.apply_recent_ingests(RecentSwordIngests.new(@config, @days))
    jlist.to_table
  end

  def hasTable
    true
  end

end
