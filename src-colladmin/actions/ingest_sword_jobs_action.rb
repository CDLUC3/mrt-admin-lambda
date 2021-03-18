require_relative 'action'
require_relative 'ingest_joblist_action'
require_relative '../lib/queue'

class IngestSwordJobsAction < IngestJoblistAction
  def initialize(config, path, myparams)
    super(config, path, myparams, "admin/bid/JOB_ONLY")
  end

  def get_title
    "Sword Jobs"
  end
end
