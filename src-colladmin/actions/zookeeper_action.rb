# frozen_string_literal: true

require_relative 'action'
require_relative '../lib/queue'
require 'zk'

# Collection Admin Task class - see config/actions.yml for description
class ZkList
  def initialize
    @jobs = []
  end

  def add_job(job)
    @jobs.push(job)
  end

  def to_table
    table = []
    js = @jobs.sort do |a, b|
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
  @@status_vals = ['Pending', 'Consumed', 'Deleted', 'Completed', 'Failed', 'Resolved']
  def initialize(config, action, path, myparams, filters)
    super(config, action, path, myparams)
    @filters = {}
    @path = '/ingest'
    @zk = ZK.new(get_zookeeper_conn)
    @jobs = ZkList.new
  end

  def perform_action
    @zk.children(@path).each do |cp|
      puts cp
      arr = @zk.get("#{@path}/#{cp}")
      next if arr[0].nil?
      data = arr[0].bytes
      return if data.length < 9
      status = data[0]
      # https://stackoverflow.com/a/68855488/3846548
      t = data[1..8].inject(0) {|m, b| (m << 8) + b }
      time = Time.at(t/1000)
      payload=data[9..].pack('c*')
      begin
        json = JSON.parse(payload)
        json['queueNode'] = 'ingest'
        json['id'] = cp
        json['date'] = time
        json['status'] = @@status_vals[status]
        puts json.to_json
        @jobs.add_job(QueueEntry.new(json))
        #puts JSON.pretty_generate(json)
      rescue => exception
        #puts exception
      end
    end
    convert_json_to_table('')
  end

  def table_rows(_body)
    @jobs.to_table
  end

  def get_zookeeper_conn
    @config.fetch('zookeeper', '').split(',').first
  end
end
