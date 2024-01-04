# frozen_string_literal: true

require_relative 'forward_to_ingest_action'
require_relative '../lib/acc_queue'

# Collection Admin Task class - see config/actions.yml for description
class AccessQueueAction < ForwardToIngestAction
  def initialize(config, action, path, myparams)
    super(config, action, path, myparams, 'admin/queues-acc')
  end

  def get_title
    'List Access Queues'
  end

  def table_headers
    AccQueueEntry.table_headers
  end

  def table_types
    AccQueueEntry.table_types
  end

  def table_rows(body)
    queue_list = AccQueueList.new(get_ingest_server, body)
    queue_list.to_table
  end

  def has_table
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
        url: "#{LambdaBase.colladmin_url}?path=cleanup-queue&queue=queues-acc&reload_path=acc-queues",
        class: 'action'
      }
    ]
  end
end
