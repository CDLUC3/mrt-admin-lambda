# frozen_string_literal: true

require_relative 'action'
require_relative '../lib/queue'
require 'stringio'
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
    @items = ZkList.new
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
    super
    @zk = ZK.new(get_zookeeper_conn)
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

# Collection Admin Task class - see config/actions.yml for description
class ZookeeperDumpAction < ZookeeperAction
  def initialize(config, action, path, myparams)
    @zkpath = myparams.fetch('zkpath', '/')
    @mode = myparams.fetch('mode', 'data')
    @full = false
    @test_results = []
    super
  end

  def data
    @buf = StringIO.new
    @buf << "Node State as of #{Time.now}:\n"
    dump_node(@zkpath)
    @buf.rewind
    @buf.read
  end

  def standard_node(n)
    n =~ %r{^/(access|batch-uuids|batches|jobs|locks|migration)(/|$)}
  end

  def system_node(n)
    n =~ %r{^/zookeeper(/|$)}
  end

  def show_data(n)
    d = get_data(n)
    df = d.is_a?(Hash) ? "\n#{JSON.pretty_generate(d).encode('UTF-8')}" : " #{d.to_s.encode('UTF-8')}"
    @buf << df unless @buf.nil?
  rescue StandardError => e
    @buf << e
  end

  def get_data(n)
    d = @zk.get(n)[0]
    return '' if d.nil?

    begin
      JSON.parse(d.encode('UTF-8'), symbolize_names: true)
    rescue JSON::ParserError
      d
    rescue StandardError => e
      "\n  #{e.class}:#{e}:\n    #{d}"
    end
  end

  def test_node(path, n)
    return if @zk.exists?(n)

    result = { path: path, test: "Test: #{n} should exist", status: 'FAIL' }
    @test_results.append([result[:path], result[:test], result[:status]])
    @buf << "\n  #{result[:test]}: #{result[:status]}" unless @buf.nil?
  end

  def test_not_node(path, n)
    return unless @zk.exists?(n)

    result = { path: path, test: "Test: #{n} should NOT exist", status: 'FAIL' }
    @test_results.append([result[:path], result[:test], result[:status]])
    @buf << "\n  #{result[:test]}: #{result[:status]}" unless @buf.nil?
  end

  def show_test(n)
    rx1 = %r{^/batches/bid[0-9]+/states/batch-.*/(jid[0-9]+)$}
    rx2 = %r{^/jobs/(jid[0-9]+)/bid$}
    rx3 = %r{^/jobs/(jid[0-9]+)$}
    rx4 = %r{^/jobs/states/[^/]*/[0-9][0-9]-(jid[0-9]+)$}

    case n
    when %r{^/batch-uuids/(.*)}
      d = get_data(n)
      test_node(n, "/batches/#{d}")
    when %r{^/batches/bid[0-9]+/submission}
      d = get_data(n).fetch(:batchID, 'na')
      test_node(n, "/batch-uuids/#{d}")
    when rx1
      jid = rx1.match(n)[1]
      test_node(n, "/jobs/#{jid}")
    when rx2
      jid = rx2.match(n)[1]
      bid = get_data(n)
      test_node(n, "/batches/#{bid}")
      d = get_data("/jobs/#{jid}/status")
      status = d.fetch(:status, 'na').downcase
      case status
      when 'deleted'
        bstatus = 'batch-deleted'
      when 'completed'
        bstatus = 'batch-completed'
      when 'failed'
        bstatus = 'batch-failed'
      else
        bstatus = 'batch-processing'
      end
      test_node(n, "/batches/#{bid}/states/#{bstatus}/#{jid}")
      %w[batch-deleted batch-completed batch-failed batch-processing].each do |ts|
        next if ts == bstatus

        test_not_node(n, "/batches/#{bid}/states/#{ts}/#{jid}")
      end
    when rx3
      jid = rx3.match(n)[1]
      d = get_data("#{n}/status")
      status = d.fetch(:status, 'na').downcase
      priority = get_data("#{n}/priority")
      test_node(n, "/jobs/states/#{status}/#{format('%02d', priority)}-#{jid}")
    when rx4
      jid = rx4.match(n)[1]
      test_node(n, "/jobs/#{jid}")
    end
  end

  def report_node(n)
    @buf << "#{n}:" unless @buf.nil?
    if standard_node(n)
      show_data(n) if @mode == 'data'
      show_test(n) if @mode == 'test'
    else
      @buf << " Unsupported\n" unless @buf.nil?
    end
    @buf << "\n" unless @buf.nil?
  end

  def check_full
    return false if @buf.nil?
    return true if @full

    # Lambda payload limit. May need to save output to S3.
    if @buf.size > 250_000
      @buf << '... (truncated at 256K)'
      @full = true
    end
    @full
  end

  def dump_node(n = '/')
    return if check_full
    return unless @zk.exists?(n)
    return if system_node(n)

    report_node(n)
    arr = @zk.children(n)
    return if arr.empty?

    arr.sort.each do |cp|
      p = "#{n}/#{cp}".gsub(%r{/+}, '/')
      dump_node(p)
    end
  end
end

## table version of the dump/test action
class ZookeeperDumpTableAction < ZookeeperDumpAction
  def initialize(config, action, path, myparams)
    super
    @mode = 'test'
  end

  def table_headers
    %w[Path Test Status]
  end

  def table_types
    %w[name name status]
  end

  def table_rows(_body)
    dump_node(@zkpath)
    @test_results
  end

  def perform_action
    convert_json_to_table('')
  end

  def has_table
    true
  end

  def init_status
    :PASS
  end
end

## Base class for new style action
class ZkAction < ZookeeperAction
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
class ZkRequeueAction < ZkAction
  def perform_action
    if @qpath =~ /access/
      acc = MerrittZK::Access.new(get_access_queue, get_id)
      acc.load(@zk)
      acc.set_status(@zk, MerrittZK::AccessState::Pending)
      { message: "Acc #{acc.id} requeued " }.to_json
    else
      job = MerrittZK::Job.new(get_id)
      job.load(@zk)
      js = job.json_property(@zk, MerrittZK::ZkKeys::STATUS)
      laststat = js.fetch(:last_successful_status, '')

      job.lock(@zk)

      case laststat
      when 'Pending', '', nil
        job.set_status(@zk, MerrittZK::JobState::Estimating, job_retry: true)
      when 'Estimating'
        job.set_status(@zk, MerrittZK::JobState::Provisioning, job_retry: true)
      when 'Provisioning'
        job.set_status(@zk, MerrittZK::JobState::Downloading, job_retry: true)
      when 'Downloading'
        job.set_status(@zk, MerrittZK::JobState::Processing, job_retry: true)
      when 'Processing'
        job.set_status(@zk, MerrittZK::JobState::Recording, job_retry: true)
      when 'Recording'
        job.set_status(@zk, MerrittZK::JobState::Notify, job_retry: true)
      end

      job.unlock(@zk)

      { message: "Job #{job.id} requeued to status #{job.status_name}" }.to_json
    end
  end
end

## Queue manipulation action using new mrt-zk
class ZkDeleteAction < ZkAction
  def perform_action
    if @qpath =~ /access/
      acc = MerrittZK::Access.new(get_access_queue, get_id)
      acc.load(@zk)
      acc.set_status(@zk, MerrittZK::AccessState::Deleted)
      { message: "Acc #{acc.id} deleted" }.to_json
    else
      job = MerrittZK::Job.new(get_id)
      job.load(@zk)
      job.set_status(@zk, MerrittZK::JobState::Deleted)
      { message: "Job #{job.id} deleted" }.to_json
    end
  end
end

## Queue manipulation action using new mrt-zk
class ZkDeleteBatchAction < ZkAction
  def perform_action
    b = MerrittZK::Batch.new(get_id)
    b.load(@zk)
    b.set_status(@zk, MerrittZK::BatchState::Deleted)
    { message: "Batch #{b.id} deleted" }.to_json
  end
end

## Queue manipulation action using new mrt-zk
class ZkUpdateReportingBatchAction < ZkAction
  def perform_action
    b = MerrittZK::Batch.new(get_id)
    b.load(@zk)
    b.set_status(@zk, MerrittZK::BatchState::UpdateReporting)
    { message: "Batch #{b.id} set to UpdateReporting" }.to_json
  end
end

## Queue manipulation action using new mrt-zk
class ZkHoldAction < ZkAction
  def perform_action
    job = MerrittZK::Job.new(get_id)
    job.load(@zk)
    job.set_status(@zk, MerrittZK::JobState::Held)
    { message: "Job #{@qpath} held" }.to_json
  end
end

## Queue manipulation action using new mrt-zk
class ZkReleaseAction < ZkAction
  def perform_action
    job = MerrittZK::Job.new(get_id)
    job.load(@zk)
    job.set_status(@zk, MerrittZK::JobState::Pending)
    { message: "Job #{@qpath} released" }.to_json
  end
end

## Class for reading the Merritt Ingest Queue
class IngestQueueZookeeperAction < ZookeeperListAction
  def perform_action
    jobs = MerrittZK::Job.list_jobs_as_json(@zk)
    jobs.each do |po|
      register_item(QueueEntry.new(po))
    end
    convert_json_to_table('')
  end
end

## Class for reading the Merritt Batch Queue
class IngestBatchQueueZookeeperAction < ZookeeperListAction
  def perform_action
    batches = MerrittZK::Batch.list_batches_as_json(@zk)
    batches.each do |po|
      register_item(BatchQueueEntry.new(po))
    end
    convert_json_to_table('')
  end
end

## Lock collection action
class CollLockZkAction < ZkAction
  def initialize(config, action, path, myparams)
    super
    @coll = myparams.fetch('coll', '')
  end

  def perform_action
    MerrittZK::Locks.lock_collection(@zk, @coll)
    { message: "Collection #{@coll} locked" }.to_json
  end
end

## Unlock collection action
class CollUnlockZkAction < ZkAction
  def initialize(config, action, path, myparams)
    super
    @coll = myparams.fetch('coll', '')
  end

  def perform_action
    MerrittZK::Locks.unlock_collection(@zk, @coll)
    { message: "Collection #{@coll} unlocked" }.to_json
  end
end

# Collection Admin Task class - see config/actions.yml for description
class CollIterateQueueAction < ZkAction
  def initialize(config, action, path, myparams)
    super
    @coll = myparams.fetch('coll', '')
  end

  def perform_action
    count = 0
    ql = QueueList.new(@zk, { held: true })
    ql.jobs.each do |j|
      job = MerrittZK::Job.new(j.queue_id)
      job.load(@zk)
      job.set_status(@zk, MerrittZK::JobState::Pending)
      count += 1
    end
    { message: "queue release submitted for #{count}" }.to_json
  end
end

# Collection Admin Task class - see config/actions.yml for description
class IterateQueueAction < ZookeeperAction
  def initialize(config, action, path, myparams)
    super
    @queue = myparams.fetch('queue', 'na')
    @reload_path = myparams.fetch('reload_path', 'na')
  end

  def perform_action
    if @queue == 'queues-acc'
      MerrittZK::Access.list_jobs_as_json(@zk).each do |job|
        qn = job.fetch(:queueNode, MerrittZK::Access::SMALL).gsub(%r{^/access/}, '')
        j = MerrittZK::Access.new(qn, job.fetch(:id, ''))
        j.load(@zk)
        next unless j.status.deletable?

        j.delete(@zk)
      end
    else
      ql = QueueList.new(@zk, { deletable: true })
      ql.batches.each_key do |bid|
        puts "Eval Deleting Batch #{bid}"
        batch = MerrittZK::Batch.find_batch_by_uuid(@zk, bid)
        if batch.nil?
          puts "Batch #{bid} not found while performing delete"
          next
        end
        batch.load(@zk)
        next unless batch.status.deletable?

        puts "Deleting Batch #{bid}"
        batch.delete(@zk)
      end
    end
    {
      redirect_location: "/web/collIndex.html?path=#{@reload_path}"
    }.to_json
  end
end

## Control Access Queue Hold/Release
class AccessLockAction < ZookeeperAction
  def initialize(config, action, path, myparams)
    super
    @op = @myparams.fetch('op', 'set')
    @op = 'state' unless %w[set clear state].include?(@op)
    @flag = @myparams.fetch('object', '')
  end

  def largeq?
    @flag == 'LargeAccessHold'
  end

  def perform_action
    lockpath = largeq? ? MerrittZK::Locks::LOCKS_QUEUE_ACCESS_LARGE : MerrittZK::Locks::LOCKS_QUEUE_ACCESS_SMALL
    case @op
    when 'set'
      largeq? ? MerrittZK::Locks.lock_large_access_queue(@zk) : MerrittZK::Locks.lock_small_access_queue(@zk)
    when 'clear'
      largeq? ? MerrittZK::Locks.unlock_large_access_queue(@zk) : MerrittZK::Locks.unlock_small_access_queue(@zk)
    end
    state = @zk.exists?(lockpath) ? 'Held' : 'Released'
    message_as_table("Lock #{@op} status result: #{lockpath}=#{state}").to_json
  end
end

## Lock ingest queue
class IngestQueueLockAction < ZookeeperAction
  def perform_action
    MerrittZK::Locks.lock_ingest_queue(@zk)
    message_as_table('Ingest Queue Locked').to_json
  end
end

## Unlock ingest queue
class IngestQueueUnlockAction < ZookeeperAction
  def perform_action
    MerrittZK::Locks.unlock_ingest_queue(@zk)
    message_as_table('Ingest Queue Unlocked').to_json
  end
end

## Display ingest locks on objects
class IngestLockAction < ZookeeperAction
  def get_title
    'List Ingest Locks'
  end

  def table_headers
    ['Ark']
  end

  def table_types
    ['ark']
  end

  def table_rows(_body)
    dir = MerrittZK::Locks::LOCKS_STORAGE
    rows = []
    @zk.children(dir).each do |cp|
      next unless cp =~ /^ark/

      ark = cp.gsub('ark-', 'ark:/').gsub('-', '/')
      rows << [ark]
    end
    rows
  end

  def perform_action
    convert_json_to_table('')
  end

  def has_table
    true
  end
end
