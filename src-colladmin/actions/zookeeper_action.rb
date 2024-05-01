# frozen_string_literal: true

require_relative 'action'
require_relative '../lib/queue'
require 'zk'
require 'merritt_zk'

# Collection Admin Task class - see config/actions.yml for description
class ZkList
  def initialize
    @items = []
  end

  def add_item(item)
    @items.push(item)
  end

  def to_table
    table = []
    js = @items.sort do |a, b|
      if a.status == b.status
        b.date <=> a.date
      else
        AdminTask.status_sort_val(a.status) <=> AdminTask.status_sort_val(b.status)
      end
    end
    js.each_with_index do |q, _i|
      table.append(q.to_table_row)
    end
    table
  end
end

class ZookeeperAction < AdminAction
  def initialize(config, action, path, myparams, filters)
    super(config, action, path, myparams)
    @filters = {}
    @zk = ZK.new(get_zookeeper_conn)
    @items = ZkList.new
  end

  def migration_level
    return :m1 if @zk.exists?("/migration/m1")
    :none
  end

  def migration_m1?
    migration_level == :m1
  end

  def zk_path
    '/tbd'
  end

  def status_vals
    []
  end

  def is_json
    false
  end

  def items
    @items
  end

  def register_item(item)
    @items.add_item(item)
  end

  def perform_action
    jobs = migration_m1? ? MerrittZK::Job.list_jobs(@zk) : MerrittZK::LegacyIngestJob.list_jobs(@zk)
    jobs.each do |po|
      register_item(QueueEntry.new(po))
    end
    convert_json_to_table('')
  end

  def table_rows(_body)
    items.to_table
  end

  def get_zookeeper_conn
    #@config.fetch('zookeeper', '').split(',').first
    @config.fetch('zookeeper', '')
  end
end

class IngestQueueZookeeperAction < ZookeeperAction
  def zk_path
    '/ingest'
  end

  def status_vals
    ['Pending', 'Consumed', 'Deleted', 'Failed', 'Completed', 'Held']
  end

  def is_json
    true
  end
end