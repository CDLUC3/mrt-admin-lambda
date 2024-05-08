# frozen_string_literal: true

require_relative 'zookeeper_action'
require_relative '../lib/inv_queue'

# Collection Admin Task class - see config/actions.yml for description
class InventoryQueueAction < ZookeeperListAction
  def initialize(config, action, path, myparams)
    super(config, action, path, myparams, 'admin/queues-inv')
  end

  def perform_action
    jobs = ZookeeperListAction.migration_m1? ? [] : MerrittZK::LegacyInventoryJob.list_jobs(@zk)
    jobs.each do |po|
      register_item(InvQueueEntry.new(po))
    end
    convert_json_to_table('')
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
        url: "#{LambdaBase.colladmin_url}?path=cleanup-queue&queue=queues-inv&reload_path=inv-queues",
        class: 'action'
      }
    ]
  end
end
