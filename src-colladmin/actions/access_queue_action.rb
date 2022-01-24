require_relative 'forward_to_ingest_action'
require_relative '../lib/acc_queue'

class AccessQueueAction < ForwardToIngestAction
  def initialize(config, action, path, myparams)
    super(config, action, path, myparams, 'admin/queues-acc')
  end

  def get_title
    "List Access Queues"
  end

  def table_headers
    AccQueueEntry.table_headers
  end

  def table_types
    AccQueueEntry.table_types
  end

  def table_rows(body)
    queueList = AccQueueList.new(get_ingest_server, body)
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
