# frozen_string_literal: true

require_relative 'action'
require_relative '../lib/queue'
require 'zk'

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

class QueueItemReader
  @@na = "NA"
  def initialize(zk_action, id, payload)
    @bytes = payload.nil? ? [] : payload.bytes
    @is_json = zk_action.is_json
    @status_vals = zk_action.status_vals
    @queue_node = zk_action.zk_path
    @id = id
  end

  def status_byte
    @bytes.empty? ? 0 : @bytes[0]
  end

  def status
    return @@na if status_byte > @status_vals.length
    @status_vals[status_byte]
  end

  def time
    return nil if @bytes.length < 9
      # https://stackoverflow.com/a/68855488/3846548
      t = @bytes[1..8].inject(0) {|m, b| (m << 8) + b }
    Time.at(t/1000)
  end

  def payload_text
    return "" if @bytes.length < 10
    @bytes[9..].pack('c*')
  end

  def payload_object
    if @is_json
      json = JSON.parse(payload_text)
    else
      json = {
        payload: payload_text
      }
    end
    json['queueNode'] = @queue_node
    json['id'] = @id
    json['date'] = time
    json['status'] = status
    json
  end

end


class ZookeeperAction < AdminAction
  def initialize(config, action, path, myparams, filters)
    super(config, action, path, myparams)
    @filters = {}
    @zk = ZK.new(get_zookeeper_conn)
    @items = ZkList.new
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
    @zk.children(zk_path).each do |cp|
      puts cp
      arr = @zk.get("#{zk_path}/#{cp}")
      po = QueueItemReader.new(self, cp, arr[0]).payload_object
      puts po.to_json
      register_item(QueueEntry.new(po))
    end
    convert_json_to_table('')
  end

  def table_rows(_body)
    items.to_table
  end

  def get_zookeeper_conn
    @config.fetch('zookeeper', '').split(',').first
  end
end

class IngestQueueZookeeperAction < ZookeeperAction
  def zk_path
    '/ingest'
  end

  def status_vals
    ['Pending', 'Consumed', 'Deleted', 'Completed', 'Failed', 'Resolved']
  end

  def is_json
    true
  end
end