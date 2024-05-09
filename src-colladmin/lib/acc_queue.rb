# frozen_string_literal: true

require_relative 'queue_json'

# access queue entry
class AccQueueEntry < QueueJson
  @@placeholder = nil
  def self.placeholder
    @@placeholder = AccQueueEntry.new({}) if @@placeholder.nil?
    @@placeholder
  end

  def initialize(json)
    super()
    add_property(
      :queueNode,
      MerrittJsonProperty.new('Queue Node').lookup_value(json, '', :queueNode)
    )
    add_property(
      :token,
      MerrittJsonProperty.new('Token').lookup_value(json, '', :token)
    )
    add_property(
      :bytes,
      MerrittJsonProperty.new('Bytes').lookup_value(json, '', :'cloud-content-byte')
    )
    add_property(
      :node,
      MerrittJsonProperty.new('Node').lookup_value(json, '', :'delivery-node')
    )
    add_property(
      :status_code,
      MerrittJsonProperty.new('Status Code').lookup_value(json, '', :queueStatus)
    )
    add_property(
      :date,
      MerrittJsonProperty.new('Date').lookup_time_value(json, '', :date)
    )
    add_property(
      :qstatus,
      MerrittJsonProperty.new('QStatus').lookup_value(json, '', :status)
    )
    add_property(
      :queueId,
      MerrittJsonProperty.new('Queue ID').lookup_value(json, '', :id)
    )
    qs = get_value(:qstatus, '')
    qt = get_value(:date, '')
    st = 'INFO'
    case qs
    when 'Completed'
      st = 'PASS'
    when 'Consumed'
      if qt < (DateTime.now - 3).to_time
        st = 'SKIP'
      elsif qt < (DateTime.now - 1).to_time
        st = 'WARN'
      else
        st = 'INFO'
      end
    when 'Failed'
      if qt < (DateTime.now - 3).to_time
        st = 'SKIP'
      else
        st = 'FAIL'
      end
    end
    add_property(
      :status,
      MerrittJsonProperty.new('Status', st)
    )
    add_property(
      :qdelete,
      MerrittJsonProperty.new('Queue Del', get_del_queue_path_m1)
    )
    add_property(
      :requeue,
      MerrittJsonProperty.new('Requeue', get_requeue_path_m1)
    )
  end

  def self.table_headers
    AccQueueEntry.placeholder.get_property_list.map do |sym|
      AccQueueEntry.placeholder.get_label(sym)
    end
  end

  def self.table_types
    arr = []
    AccQueueEntry.placeholder.get_property_list.each do |sym|
      type = ''
      type = 'status' if sym == :status
      type = 'name' if sym == :token
      type = 'bytes' if sym == :bytes
      type = 'datetime' if sym == :date
      if ZookeeperListAction.migration_m3?
        type = 'qdelete-mrtzk' if sym == :qdelete
        type = 'requeue-mrtzk' if sym == :requeue
      else
        type = 'qdelete-legacy' if sym == :qdelete
        type = 'requeue-legacy' if sym == :requeue
      end
      arr.append(type)
    end
    arr
  end

  def to_table_row
    arr = []
    AccQueueEntry.placeholder.get_property_list.each do |sym|
      v = get_value(sym)
      arr.append(v)
    end
    arr
  end

  def status
    get_value(:status)
  end

  def date
    get_value(:date)
  end
end
