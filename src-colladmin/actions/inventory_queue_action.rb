require_relative 'forward_to_ingest_action'
require_relative '../lib/inv_queue'

class InventoryQueueAction < ForwardToIngestAction
  def initialize(config, path, myparams)
    super(config, path, myparams, 'admin/queues-inv')
  end

  def get_title
    "List Inventory Queues"
  end

  def table_headers
    InvQueueEntry.table_headers
  end

  def table_types
    InvQueueEntry.table_types
  end

  def table_rows(body)
    queueList = InvQueueList.new(get_ingest_server, body)
    queueList.to_table
  end

  def hasTable
    true
  end

  def init_status
    :PASS
  end

  def page_size
    100
  end

end