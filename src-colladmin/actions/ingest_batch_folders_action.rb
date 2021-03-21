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
      'Date'
    ]
  end

  def table_types
    [
      'qbatch', 
      ''
    ]
  end

  def table_rows(body)
    BatchFolderList.new(body).to_table
  end

  def hasTable
    true
  end

end
