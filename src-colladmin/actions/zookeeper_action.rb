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

## Base class for actions that interact directly with Zookeeper using the mrt-zk library
class ZookeeperListAction < AdminAction
  def initialize(config, action, path, myparams, _filters)
    super(config, action, path, myparams)
    @filters = {}
    @zk = ZK.new(get_zookeeper_conn)
    @items = ZkList.new
  end

  def migration_level
    return :m1 if @zk.exists?('/migration/m1')

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

  attr_reader :items

  def register_item(item)
    @items.add_item(item)
  end

  def perform_action
    convert_json_to_table('')
  end

  def table_rows(_body)
    items.to_table
  end

  def get_zookeeper_conn
    @config.fetch('zookeeper', '')
  end
end

class ZookeeperAction < AdminAction
  def initialize(config, action, path, myparams)
    super(config, action, path, myparams)
    @zk = ZK.new(get_zookeeper_conn)
    @qid = myparams.fetch('queue-path', '')
  end

  def get_zookeeper_conn
    @config.fetch('zookeeper', '')
  end

  def perform_action
    { message: "No response for #{@path}: #{@qid}" }.to_json
  rescue StandardError => e
    log(e.message)
    log(e.backtrace)
    { error: "#{e.message} for #{@path}: #{@qid}" }.to_json
  end
end

class ZkRequeueM1Action < ZookeeperAction
end

class ZkDeleteM1Action < ZookeeperAction
end

class ZkHoldM1Action < ZookeeperAction
end

class ZkReleaseM1Action < ZookeeperAction
end

class LegacyZkAction < ZookeeperAction
  def status_vals
    MerrittZK::LegacyIngestJob.status_vals
  end

  def prefix
    'na'
  end

  def path
    "/#{prefix}/#{@qid}"
  end

  def bytes
    data = @zk.get(path)
    return if data.nil?
    data[0].bytes
  end

  def orig_stat
    return if bytes.nil?
    bytes[0]
  end

  def orig_stat_name
    return if orig_stat.nil?
    status_vals[orig_stat]
  end

  def write_status(status)
    pbytes = bytes
    pbytes[0] = status
    @zk.set(path, pbytes.pack("CCCCCCCCCc*"))
  end

  def set_status(status)
    i = status_vals.find_index(status)
    return if i.nil?
    orig_name = orig_stat_name
    return {message: 'Illegal status'}.to_json unless check_status(orig_name)
    write_status(i)
    {message: "Status #{orig_name} -- > #{status}"}.to_json
  end

  def check_status(status)
    true
  end
end

class LegacyIngestZkAction < LegacyZkAction
  def prefix
    'ingest'
  end

end

class ZkRequeueLegacyIngestAction < LegacyIngestZkAction
  def perform_action
    set_status('Pending')
  end

  def check_status(status)
    %w[Consumed Failed].include?(status)
  end
end

class ZkDeleteLegacyIngestAction < LegacyIngestZkAction
  def perform_action
    set_status('Deleted')
  end

  def check_status(status)
    %w[Failed Completed].include?(status)
  end
end

class ZkHoldLegacyIngestAction < LegacyIngestZkAction
  def perform_action
    set_status('Held')
  end

  def check_status(status)
    %w[Pending].include?(status)
  end
end

class ZkReleaseLegacyIngestAction < LegacyIngestZkAction
  def perform_action
    set_status('Pending')
  end

  def check_status(status)
    %w[Held].include?(status)
  end
end

## Class for reading the legacy Merritt Ingest Queue
class IngestQueueZookeeperAction < ZookeeperListAction
  def zk_path
    '/ingest'
  end

  def status_vals
    MerrittZK::LegacyIngestJob.status_vals
  end

  def is_json
    true
  end

  def perform_action
    $migration = migration_level if migration_m1?
    jobs = migration_m1? ? MerrittZK::Job.list_jobs(@zk) : MerrittZK::LegacyIngestJob.list_jobs(@zk)
    jobs.each do |po|
      register_item(QueueEntry.new(po))
    end
    convert_json_to_table('')
  end
end

class InventoryQueueZookeeperAction < ZookeeperListAction
  def zk_path
    '/mrt.inventory.full'
  end

  def status_vals
    MerrittZK::LegacyInventoryJob.status_vals
  end

  def is_json
    true
  end

  def perform_action
    $migration = migration_level if migration_m1?
    jobs = migration_m1? ? [] : MerrittZK::LegacyInventoryJob.list_jobs(@zk)
    jobs.each do |po|
      register_item(InvQueueEntry.new(po))
    end
    convert_json_to_table('')
  end
end
