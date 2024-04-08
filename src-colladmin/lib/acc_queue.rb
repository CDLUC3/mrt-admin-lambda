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
      MerrittJsonProperty.new('Queue Node').lookup_value(json, 'que', 'queueNode')
    )
    add_property(
      :token,
      MerrittJsonProperty.new('Token').lookup_value(json, 'que', 'token')
    )
    add_property(
      :bytes,
      MerrittJsonProperty.new('Bytes').lookup_value(json, 'que', 'cloudContentByte')
    )
    add_property(
      :node,
      MerrittJsonProperty.new('Node').lookup_value(json, 'que', 'deliveryNode')
    )
    add_property(
      :status_code,
      MerrittJsonProperty.new('Status Code').lookup_value(json, 'que', 'queueStatus')
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
      MerrittJsonProperty.new('Queue Del', get_queue_path(requeue: false))
    )
    add_property(
      :requeue,
      MerrittJsonProperty.new('Requeue', get_queue_path(requeue: true))
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
      type = 'qdelete' if sym == :qdelete
      type = 'requeue' if sym == :requeue
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

# access queue
class AccQueue < MerrittJson
  def initialize(queue_list, body)
    data = JSON.parse(body)
    data = fetch_hash_val(data, 'que:queueState')
    data = fetch_hash_val(data, 'que:queueEntries')
    list = fetch_array_val(data, 'que:queueEntryState')
    list.each do |obj|
      q = AccQueueEntry.new(obj)
      queue_list.tokens.append(q)
    end
    super()
  end
end

# list of available access queues
class AccQueueList < MerrittJson
  def initialize(ingest_server, body, _filter = {})
    super()
    @ingest_server = ingest_server
    @body = body
    @tokens = []
    retrieve_queues
  end

  def self.get_queue_list(ingest_server, filter = {})
    qjson = HttpGetJson.new(ingest_server, 'admin/queues-acc')
    AccQueueList.new(ingest_server, qjson.body, filter)
  end

  def retrieve_queues
    data = JSON.parse(@body)
    data = fetch_hash_val(data, 'ingq:ingestQueueNameState')
    data = fetch_hash_val(data, 'ingq:ingestQueueName')
    fetch_array_val(data, 'ingq:ingestQueue').each do |qjson|
      node = fetch_hash_val(qjson, 'ingq:node')
      begin
        qjson = HttpGetJson.new(@ingest_server, "admin/queue-acc#{node}")
        next unless qjson.status == 200

        AccQueue.new(self, qjson.body)
      rescue StandardError => e
        LambdaBase.log(e.message)
        LambdaBase.log(e.backtrace)
      end
    end
  end

  attr_reader :tokens, :body

  def to_table
    table = []
    ts = @tokens.sort do |a, b|
      if a.status == b.status
        b.date <=> a.date
      else
        AdminTask.status_sort_val(a.status) <=> AdminTask.status_sort_val(b.status)
      end
    end
    ts.each_with_index do |q, _i|
      table.append(q.to_table_row)
    end
    table
  end
end
