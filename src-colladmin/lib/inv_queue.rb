require_relative 'merritt_json'

class InvQueueEntry < MerrittJson
  @@placeholder = nil
  def self.placeholder
    @@placeholder = InvQueueEntry.new({}) if @@placeholder.nil?
    @@placeholder
  end

  def initialize(json)
    super()
    addProperty(
      :queueNode, 
      MerrittJsonProperty.new("Queue Node").lookupValue(json, "que", "queueNode")
    )
    addProperty(
      :manifestURL, 
      MerrittJsonProperty.new("Manifest URL").lookupValue(json, "que", "manifestURL")
    )
    addProperty(
      :date, 
      MerrittJsonProperty.new("Date").lookupTimeValue(json, "que", "date")
    )
    addProperty(
      :qstatus, 
      MerrittJsonProperty.new("QStatus").lookupValue(json, "que", "status")
    )
    addProperty(
      :queueId, 
      MerrittJsonProperty.new("Queue ID").lookupValue(json, "que", "iD")
    )
    qs = getValue(:qstatus, "")
    qt = getValue(:date, "")
    st = 'INFO'
    if (qs == "Completed")
      st = 'PASS'
    elsif (qs == "Consumed")
      if (qt < (DateTime.now - 2).to_time)
        st = 'FAIL'
      elsif (qt < (DateTime.now - 1).to_time)
        st = 'WARN'
      else
        st = 'INFO'        
      end
    elsif (qs == "Failed")
      if (qt < (DateTime.now - 14).to_time)
        st = 'SKIP'
      else
        st = 'FAIL'
      end
    end
    addProperty(
      :status, 
      MerrittJsonProperty.new("Status", st)
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
  def initialize(ingest_server, body, filter = "")
    super()
    @ingest_server = ingest_server
    @body = body
    @manifests = []
    retrieveQueues
  end

  def self.get_queue_list(ingest_server, filter = "")
    qjson = HttpGetJson.new(ingest_server, "admin/queues-inv")
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
      rescue => e
        puts(e.message)
        puts(e.backtrace)
      end
    end
  end

  def manifests
    @manifests
  end

  def body
    @body
  end

  def to_table
    table = []
    @manifests.sort{
      # reverse sort on status then date, "Completed" should fall to bottom
      |a,b| a.status == b.status ? b.date <=> a.date : AdminTask.status_sort_val(a.status) <=> AdminTask.status_sort_val(b.status)
    }.each_with_index do |q, i|
      table.append(q.to_table_row)
    end
    table
  end

end

