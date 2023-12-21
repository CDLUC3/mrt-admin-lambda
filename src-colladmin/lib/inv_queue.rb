# frozen_string_literal: true

require_relative 'queue_json'

class InvQueueEntry < QueueJson
  @@placeholder = nil
  def self.placeholder
    @@placeholder = InvQueueEntry.new({}) if @@placeholder.nil?
    @@placeholder
  end

  def initialize(json)
    super()
    addProperty(
      :queueNode,
      MerrittJsonProperty.new('Queue Node').lookupValue(json, 'que', 'queueNode')
    )
    addProperty(
      :manifestURL,
      MerrittJsonProperty.new('Manifest URL').lookupValue(json, 'que', 'manifestURL')
    )
    addProperty(
      :date,
      MerrittJsonProperty.new('Date').lookupTimeValue(json, 'que', 'date')
    )
    addProperty(
      :qstatus,
      MerrittJsonProperty.new('QStatus').lookupValue(json, 'que', 'status')
    )
    addProperty(
      :queueId,
      MerrittJsonProperty.new('Queue ID').lookupValue(json, 'que', 'iD')
    )
    qs = getValue(:qstatus, '')
    qt = getValue(:date, '')
    st = 'INFO'
    case qs
    when 'Completed'
      st = 'PASS'
    when 'Consumed'
      st = if qt < (DateTime.now - 2).to_time
             'FAIL'
           elsif qt < (DateTime.now - 1).to_time
             'WARN'
           else
             'INFO'
           end
    when 'Failed'
      st = if qt < (DateTime.now - 14).to_time
             'SKIP'
           else
             'FAIL'
           end
    end
    addProperty(
      :status,
      MerrittJsonProperty.new('Status', st)
    )

    addProperty(
      :qdelete,
      MerrittJsonProperty.new('Queue Del', get_queue_path(false))
    )
    addProperty(
      :requeue,
      MerrittJsonProperty.new('Requeue', get_queue_path(true))
    )
  end

  def self.table_headers
    arr = []
    InvQueueEntry.placeholder.getPropertyList.each do |sym|
      arr.append(InvQueueEntry.placeholder.getLabel(sym))
    end
    arr
  end

  def self.table_types
    arr = []
    InvQueueEntry.placeholder.getPropertyList.each do |sym|
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
    InvQueueEntry.placeholder.getPropertyList.each do |sym|
      v = getValue(sym)
      arr.append(v)
    end
    arr
  end

  def status
    getValue(:status)
  end

  def date
    getValue(:date)
  end
end

class InventoryQueue < MerrittJson
  def initialize(queueList, body)
    data = JSON.parse(body)
    data = fetchHashVal(data, 'que:queueState')
    data = fetchHashVal(data, 'que:queueEntries')
    list = fetchArrayVal(data, 'que:queueEntryState')
    list.each do |obj|
      q = InvQueueEntry.new(obj)
      queueList.manifests.append(q)
    end
  end
end

class InvQueueList < MerrittJson
  def initialize(ingest_server, body, _filter = {})
    super()
    @ingest_server = ingest_server
    @body = body
    @manifests = []
    retrieveQueues
  end

  def self.get_queue_list(ingest_server, filter = {})
    qjson = HttpGetJson.new(ingest_server, 'admin/queues-inv')
    InvQueueList.new(ingest_server, qjson.body, filter)
  end

  def retrieveQueues
    data = JSON.parse(@body)
    data = fetchHashVal(data, 'ingq:ingestQueueNameState')
    data = fetchHashVal(data, 'ingq:ingestQueueName')
    fetchArrayVal(data, 'ingq:ingestQueue').each do |qjson|
      node = fetchHashVal(qjson, 'ingq:node')
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
    @manifests.sort do |a, b|
      a.status == b.status ? b.date <=> a.date : AdminTask.status_sort_val(a.status) <=> AdminTask.status_sort_val(b.status)
    end.each_with_index do |q, _i|
      table.append(q.to_table_row)
    end
    table
  end
end
