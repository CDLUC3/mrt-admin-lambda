require_relative 'merritt_json'
class AccQueueEntry < MerrittJson
  @@placeholder = nil
  def self.placeholder
    @@placeholder = AccQueueEntry.new({}) if @@placeholder.nil?
    @@placeholder
  end

 def initialize(json)
    super()
    addProperty(
      :queueNode, 
      MerrittJsonProperty.new("Queue Node").lookupValue(json, "que", "queueNode")
    )
    addProperty(
      :token, 
      MerrittJsonProperty.new("Token").lookupValue(json, "que", "token")
    )
    addProperty(
      :bytes, 
      MerrittJsonProperty.new("Bytes").lookupValue(json, "que", "cloudContentByte")
    )
    addProperty(
      :node, 
      MerrittJsonProperty.new("Node").lookupValue(json, "que", "deliveryNode")
    )
    addProperty(
      :status_code, 
      MerrittJsonProperty.new("Status Code").lookupValue(json, "que", "queueStatus")
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
      if (qt < (DateTime.now - 3).to_time)
        st = 'SKIP'
      elsif (qt < (DateTime.now - 1).to_time)
        st = 'WARN'
      else
        st = 'INFO'        
      end
    elsif (qs == "Failed")
      if (qt < (DateTime.now - 3).to_time)
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
    AccQueueEntry.placeholder.getPropertyList.each do |sym|
      arr.append(AccQueueEntry.placeholder.getLabel(sym))
    end
    arr
  end

  def self.table_types
    arr = []
    AccQueueEntry.placeholder.getPropertyList.each do |sym|
      type = ''
      type = 'status' if sym == :status
      type = 'name' if sym == :token
      type = 'bytes' if sym == :bytes
      arr.append(type)
    end
    arr
  end

  def to_table_row
    arr = []
    AccQueueEntry.placeholder.getPropertyList.each do |sym|
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

class AccQueue < MerrittJson
  def initialize(queueList, body)
    data = JSON.parse(body)
    data = fetchHashVal(data, 'que:queueState')
    data = fetchHashVal(data, 'que:queueEntries')
    list = fetchArrayVal(data, 'que:queueEntryState')
    list.each do |obj|
      q = AccQueueEntry.new(obj)
      queueList.tokens.append(q)
    end
  end
end

class AccQueueList < MerrittJson
  def initialize(ingest_server, body, filter = "")
    super()
    @ingest_server = ingest_server
    @body = body
    @tokens = []
    retrieveQueues
  end

  def self.get_queue_list(ingest_server, filter = "")
    qjson = HttpGetJson.new(ingest_server, "admin/queues-acc")
    AccQueueList.new(ingest_server, qjson.body, filter)
  end

  def retrieveQueues
    data = JSON.parse(@body)
    data = fetchHashVal(data, 'ingq:ingestQueueNameState')
    data = fetchHashVal(data, 'ingq:ingestQueueName')
    fetchArrayVal(data, 'ingq:ingestQueue').each do |qjson|
      node = fetchHashVal(qjson, 'ingq:node')
      begin
        qjson = HttpGetJson.new(@ingest_server, "admin/queue-acc#{node}")
        next unless qjson.status == 200
        AccQueue.new(self, qjson.body)
      rescue => e
        puts(e.message)
        puts(e.backtrace)
      end
    end
  end

  def tokens
    @tokens
  end

  def body
    @body
  end

  def to_table
    table = []
    @tokens.sort{
      # reverse sort on status then date, "Completed" should fall to bottom
      |a,b| a.status == b.status ? b.date <=> a.date : AdminTask.status_sort_val(a.status) <=> AdminTask.status_sort_val(b.status)
    }.each_with_index do |q, i|
      table.append(q.to_table_row)
    end
    table
  end

end

