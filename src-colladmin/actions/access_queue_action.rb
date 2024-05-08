# frozen_string_literal: true

require_relative 'zookeeper_action'
require_relative '../lib/acc_queue'

# Collection Admin Task class - see config/actions.yml for description
class AccessQueueAction < ZookeeperListAction
  def initialize(config, action, path, myparams)
    super(config, action, path, myparams, 'admin/queues-acc')
  end

  def perform_action
    jobs = []
    if ZookeeperListAction.migration_m3?
      jobs = MerrittZK::Access.list_jobs(@zk)
    else
      jobs = MerrittZK::LegacyAccessJob.list_jobs(@zk)
    end
    jobs.each do |po|
      register_item(AccQueueEntry.new(po))
    end
    convert_json_to_table('')
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
