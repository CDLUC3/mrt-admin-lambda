require_relative 'forward_to_ingest_action'

class IngestQueueAction < ForwardToIngestAction
  def initialize(config, path, myparams)
    super(config, path, myparams, 'admin/queues')
  end

  def get_title
    "List Ingest Queues"
  end

  def table_headers
    QueueEntry.table_headers
  end

  def table_types
    QueueEntry.table_types
  end

  def table_rows(body)
    queueList = QueueList.new(get_ingest_server, body)
    queueList.to_table
  end

  def hasTable
    true
  end

  def init_status
    :PASS
  end

  def get_alternative_queries
    [
      {
        label: 'Completed Ingests', 
        url: '/index.html?path=recent_ingests'
      }
    ]
  end

end
