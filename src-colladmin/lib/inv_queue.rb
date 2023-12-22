# frozen_string_literal: true

require_relative 'queue_json'

# inventory queue entry
class InvQueueEntry < QueueJson
  @@placeholder = nil
  def self.placeholder
    @@placeholder = InvQueueEntry.new({}) if @@placeholder.nil?
    @@placeholder
  end

  def initialize(json)
    super()
    add_property(
      :queueNode,
      MerrittJsonProperty.new('Queue Node').lookup_value(json, 'que', 'queueNode')
    )
    add_property(
      :manifestURL,
      MerrittJsonProperty.new('Manifest URL').lookup_value(json, 'que', 'manifestURL')
    )
    add_property(
      :date,
      MerrittJsonProperty.new('Date').lookup_time_value(json, 'que', 'date')
    )
    add_property(
      :qstatus,
      MerrittJsonProperty.new('QStatus').lookup_value(json, 'que', 'status')
    )
    add_property(
      :queueId,
      MerrittJsonProperty.new('Queue ID').lookup_value(json, 'que', 'iD')
    )
    qs = get_value(:qstatus, '')
    qt = get_value(:date, '')
    st = 'INFO'
    case qs
    when 'Completed'
      st = 'PASS'
    when 'Consumed'
      if qt < (DateTime.now - 2).to_time
        st = 'FAIL'
      elsif qt < (DateTime.now - 1).to_time
        st = 'WARN'
      else
        st = 'INFO'
      end
    when 'Failed'
      if qt < (DateTime.now - 14).to_time
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
      MerrittJsonProperty.new('Queue Del', get_queue_path(requeue: false))
    )
    add_property(
      :requeue,
      MerrittJsonProperty.new('Requeue', get_queue_path(requeue: true))
    )
  end

  def self.table_headers
    arr = []
    InvQueueEntry.placeholder.get_property_list.each do |sym|
      arr.append(InvQueueEntry.placeholder.get_label(sym))
    end
    arr
  end

  def self.table_types
    arr = []
    InvQueueEntry.placeholder.get_property_list.each do |sym|
      type = ''
      type = 'status' if sym == :status
      type = 'datetime' if sym == :date
      type = 'qdelete' if sym == :qdelete
      type = 'requeue' if sym == :requeue
      arr.append(type)
    end
    arr
  end

  def to_table_row
    arr = []
    InvQueueEntry.placeholder.get_property_list.each do |sym|
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

# inventory queue
class InventoryQueue < MerrittJson
  def initialize(queue_list, body)
    data = JSON.parse(body)
    data = fetch_hash_val(data, 'que:queueState')
    data = fetch_hash_val(data, 'que:queueEntries')
    list = fetch_array_val(data, 'que:queueEntryState')
    list.each do |obj|
      q = InvQueueEntry.new(obj)
      queue_list.manifests.append(q)
    end
    super()
  end
end

# list of all inventory queues - only one exists
class InvQueueList < MerrittJson
  def initialize(ingest_server, body, _filter = {})
    super()
    @ingest_server = ingest_server
    @body = body
    @manifests = []
    retrieve_queues
  end

  def self.get_queue_list(ingest_server, filter = {})
    qjson = HttpGetJson.new(ingest_server, 'admin/queues-inv')
    InvQueueList.new(ingest_server, qjson.body, filter)
  end

  def retrieve_queues
    data = JSON.parse(@body)
    data = fetch_hash_val(data, 'ingq:ingestQueueNameState')
    data = fetch_hash_val(data, 'ingq:ingestQueueName')
    fetch_array_val(data, 'ingq:ingestQueue').each do |qjson|
      node = fetch_hash_val(qjson, 'ingq:node')
      begin
        qjson = HttpGetJson.new(@ingest_server, "admin/queue-inv#{node}")
        next unless qjson.status == 200

        InventoryQueue.new(self, qjson.body)
      rescue StandardError => e
        LambdaBase.log(e.message)
        LambdaBase.log(e.backtrace)
      end
    end
  end

  attr_reader :manifests, :body

  def to_table
    table = []
    ms = @manifests.sort do |a, b|
      if a.status == b.status
        b.date <=> a.date
      else
        AdminTask.status_sort_val(a.status) <=> AdminTask.status_sort_val(b.status)
      end
    end
    ms.each_with_index do |q, _i|
      table.append(q.to_table_row)
    end
    table
  end
end
