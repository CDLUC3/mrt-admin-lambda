# frozen_string_literal: true

require_relative 'forward_to_ingest_action'
require_relative '../lib/inv_queue'

class InventoryQueueAction < ForwardToIngestAction
  def initialize(config, action, path, myparams)
    super(config, action, path, myparams, 'admin/queues-inv')
  end

  def get_title
    'List Inventory Queues'
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

  def get_alternative_queries
    [
      {
        label: 'Requeue All',
        url: '',
        class: 'action requeue-all'
      },
      {
        label: 'Delete All',
        url: '',
        class: 'action deleteq-all'
      },
      {
        label: 'Cleanup Queue',
        url: "#{LambdaBase.colladmin_url}?path=cleanup-queue&queue=queues-inv&reload_path=inv-queues",
        class: 'action'
      }
    ]
  end
end
