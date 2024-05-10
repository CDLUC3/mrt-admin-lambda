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
  def initialize(config, action, path, myparams, _filters = {})
    super(config, action, path, myparams)
    @filters = {}
    @zk = ZK.new(get_zookeeper_conn)
    ZookeeperListAction.migration_level(@zk)
    @items = ZkList.new
  end

  def self.migration_level(zk)
    $migration = []
    $migration << :m1 if zk.exists?('/migration/m1')
    $migration << :m3 if zk.exists?('/migration/m3')
  end

  def self.migration_m1?
    return false if $migration.nil?

    $migration.include?(:m1)
  end

  def self.migration_m3?
    return false if $migration.nil?

    $migration.include?(:m3)
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

## Queue manipulation action using mrt-zk
class ZookeeperAction < AdminAction
  def initialize(config, action, path, myparams)
    super(config, action, path, myparams)
    @zk = ZK.new(get_zookeeper_conn)
    ZookeeperListAction.migration_level(@zk)
    @qpath = myparams.fetch('queue-path', '')
  end

  def get_zookeeper_conn
    @config.fetch('zookeeper', '')
  end

  def perform_action
    { message: "No response for #{@path}: #{@qpath}" }.to_json
  rescue StandardError => e
    log(e.message)
    log(e.backtrace)
    { error: "#{e.message} for #{@path}: #{@qpath}" }.to_json
  end
end

## Base class for new style action
class ZkM1Action < ZookeeperAction
  def get_id
    @qpath.split('/')[-1]
  end

  def get_access_queue
    @qpath.split('/')[-2]
  end

  def perform_action
    { message: "path: #{@path}; qpath: #{@qpath}" }.to_json
  end
end

## Queue manipulation action using new mrt-zk
class ZkRequeueM1Action < ZkM1Action
  def perform_action
    if @qpath =~ /access/
      acc = MerrittZK::Access.new(get_access_queue, get_id)
      acc.load(@zk)
      acc.set_status(@zk, MerrittZK::AccessState::Pending)
      { message: "Acc #{acc.id} requeue not yet implemented " }.to_json
    else
      job = MerrittZK::Job.new(get_id)
      job.load(@zk)
      js = job.json_property(@zk, MerrittZK::ZkKeys::STATUS)
      laststat = js.fetch(:last_successful_status, '')
      case laststat
      when 'Estimating', '', nil
        job.set_status(@zk, MerrittZK::JobState::Estimating)
      when 'Downloading'
        job.set_status(@zk, MerrittZK::JobState::Downloading)
      when 'Processing'
        job.set_status(@zk, MerrittZK::JobState::Processing)
      when 'Recording'
        job.set_status(@zk, MerrittZK::JobState::Recording)
      when 'Notify'
        job.set_status(@zk, MerrittZK::JobState::Notify)
      end
      { message: "Job #{job.id} requeued to status #{job.status_name}" }.to_json
    end
  end
end

## Queue manipulation action using new mrt-zk
class ZkDeleteM1Action < ZkM1Action
  def perform_action
    if @qpath =~ /access/
      acc = MerrittZK::Access.new(get_access_queue, get_id)
      acc.load(@zk)
      acc.set_status(@zk, MerrittZK::AccessState::Deleted)
      { message: "Acc #{@acc.id} deleted" }.to_json
    else
      job = MerrittZK::Job.new(get_id)
      job.load(@zk)
      job.set_status(@zk, MerrittZK::JobState::Deleted)
      { message: "Job #{@job.id} deleted" }.to_json
    end
  end
end

## Queue manipulation action using new mrt-zk
class ZkHoldM1Action < ZkM1Action
  def perform_action
    job = MerrittZK::Job.new(get_id)
    job.load(@zk)
    job.set_status(@zk, MerrittZK::JobState::Held)
    { message: "Job #{@qpath} held" }.to_json
  end
end

## Queue manipulation action using new mrt-zk
class ZkReleaseM1Action < ZkM1Action
  def perform_action
    job = MerrittZK::Job.new(get_id)
    job.load(@zk)
    job.set_status(@zk, MerrittZK::JobState::Pending)
    { message: "Job #{@qpath} released" }.to_json
  end
end

## Legacy Queue manipulation action using new mrt-zk
class LegacyZkAction < ZookeeperAction
  def legacy_status_vals
    MerrittZK::LegacyItem::STATUS_VALS
  end

  def prefix
    'na'
  end

  attr_reader :qpath

  def bytes
    data = @zk.get(qpath)
    return if data.nil?

    data[0].bytes
  end

  def orig_stat
    return if bytes.nil?

    bytes[0]
  end

  def orig_stat_name
    return if orig_stat.nil?

    legacy_status_vals[orig_stat]
  end

  def write_status(status)
    pbytes = bytes
    pbytes[0] = status
    @zk.set(qpath, pbytes.pack('CCCCCCCCCc*'))
  end

  def set_status(status)
    i = legacy_status_vals.find_index(status)
    return if i.nil?

    orig_name = orig_stat_name
    return { message: 'Illegal status' }.to_json unless check_status(orig_name)

    write_status(i)
    { message: "Status #{orig_name} -- > #{status}" }.to_json
  end

  def check_status(_status)
    true
  end
end

##
# Legacy Ingest queue action
class ZkRequeueLegacyAction < LegacyZkAction
  def perform_action
    set_status('Pending')
  end

  def check_status(status)
    %w[Consumed Failed].include?(status)
  end
end

##
# Legacy Ingest queue action
class ZkDeleteLegacyAction < LegacyZkAction
  def perform_action
    set_status('Deleted')
  end

  def check_status(status)
    %w[Failed Completed].include?(status)
  end
end

##
# Legacy Ingest queue action
class ZkHoldLegacyAction < LegacyZkAction
  def perform_action
    set_status('Held')
  end

  def check_status(status)
    %w[Pending].include?(status)
  end
end

##
# Legacy Ingest queue action
class ZkReleaseLegacyAction < LegacyZkAction
  def perform_action
    set_status('Pending')
  end

  def check_status(status)
    %w[Held].include?(status)
  end
end

## Class for reading the legacy Merritt Ingest Queue
class IngestQueueZookeeperAction < ZookeeperListAction
  def perform_action
    jobs = []
    if ZookeeperListAction.migration_m1?
      jobs = MerrittZK::Job.list_jobs_as_json(@zk)
    else
      MerrittZK::LegacyIngestJob.list_jobs_as_json(@zk)
    end
    jobs.each do |po|
      register_item(QueueEntry.new(po))
    end
    convert_json_to_table('')
  end
end
