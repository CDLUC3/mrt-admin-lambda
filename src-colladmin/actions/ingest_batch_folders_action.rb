require_relative 'action'
require_relative 'ingest_joblist_action'
require_relative '../lib/queue'

class IngestBatchFoldersAction < IngestJoblistAction
  def initialize(config, path, myparams)
    @days = myparams.fetch("days", "7").to_i 
    @days = 60 if @days > 60
    super(config, path, myparams, "admin/bids/#{@days}")
  end

  def get_title
    "Batch Folders - Last #{@days} days"
  end

  def table_headers
    [
      'Batch', 
      'Date'
    ]
  end
end
