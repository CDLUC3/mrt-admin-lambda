require_relative 'action'
require_relative '../lib/queue'

class IngestBatchFoldersAction < ForwardToIngestAction
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
      'Date',
      'Queue'
    ]
  end

  def table_types
    [
      '', 
      '',
      'qbatchnote'
    ]
  end

  def table_rows(body)
    bflist = BatchFolderList.new(body)
    bflist.apply_queue_list(QueueList.get_queue_list(get_ingest_server))
    bflist.to_table
  end

  def hasTable
    true
  end

end
