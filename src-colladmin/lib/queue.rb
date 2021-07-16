require_relative 'merritt_json'
class QueueEntry < MerrittJson
  @@placeholder = nil
  def self.placeholder
    @@placeholder = QueueEntry.new({}) if @@placeholder.nil?
    @@placeholder
  end

  def initialize(json)
    super()
    addProperty(
      :queueNode, 
      MerrittJsonProperty.new("Queue Node").lookupValue(json, "que", "queueNode")
    )
    addProperty(
      :bid, 
      MerrittJsonProperty.new("Batch").lookupValue(json, "que", "batchID")
    )
    addProperty(
      :job, 
      MerrittJsonProperty.new("Job").lookupValue(json, "que", "jobID")
    )
    addProperty(
      :profile, 
      MerrittJsonProperty.new("Profile").lookupValue(json, "que", "profile")
    )
    addProperty(
      :date, 
      MerrittJsonProperty.new("Date").lookupValue(json, "que", "date")
    )
    addProperty(
      :user, 
      MerrittJsonProperty.new("User").lookupValue(json, "que", "user")
    )
    addProperty(
      :title, 
      MerrittJsonProperty.new("Title").lookupValue(json, "que", "objectTitle")
    )
    addProperty(
      :fileType, 
      MerrittJsonProperty.new("File Type").lookupValue(json, "que", "fileType")
    )
    addProperty(
      :qstatus, 
      MerrittJsonProperty.new("QStatus").lookupValue(json, "que", "status")
    )
    addProperty(
      :queue, 
      MerrittJsonProperty.new("Name").lookupValue(json, "que", "name")
    )
    addProperty(
      :queueId, 
      MerrittJsonProperty.new("Queue ID").lookupValue(json, "que", "iD")
    )
    addProperty(
      :status, 
      MerrittJsonProperty.new("Status", getValue(:qstatus, "") == "Failed" ? 'FAIL' : 'PASS')
    )
  end

  def checkFilter(filter)
    filter.empty? || bid == filter
  end

  def self.table_headers
    arr = []
    QueueEntry.placeholder.getPropertyList.each do |sym|
      arr.append(QueueEntry.placeholder.getLabel(sym))
    end
    arr
  end

  def self.table_types
    arr = []
    QueueEntry.placeholder.getPropertyList.each do |sym|
      type = ''
      type = 'qbatch' if sym == :bid
      type = 'qjob' if sym == :job
      type = 'status' if sym == :status
      arr.append(type)
    end
    arr
  end

  def to_table_row
    arr = []
    QueueEntry.placeholder.getPropertyList.each do |sym|
      v = getValue(sym)
      v = "#{bid}/#{v}" if sym == :job
      arr.append(v)
    end
    arr
  end

  def bid
    getValue(:bid)
  end

  def jid
    getValue(:job)
  end

  def profile
    getValue(:profile)
  end

  def status
    getValue(:status)
  end

  def user
    getValue(:user)
  end

  def title
    getValue(:title)
  end

  def fileType
    getValue(:fileType)
  end
  
  def date
    getValue(:date)
  end
end

class QueueBatch < MerrittJson
  def initialize(bid, submitter)
    @bid = bid
    @submitter = submitter
    @jobs = []
  end

  def addJob(qj)
    @jobs.append(qj)
  end

  def bid
    @bid
  end

  def submitter
    @submitter
  end

  def num_jobs
    @jobs.length
  end
end

class IngestQueue < MerrittJson
  def initialize(queueList, body)
    data = JSON.parse(body)
    data = fetchHashVal(data, 'que:queueState')
    data = fetchHashVal(data, 'que:queueEntries')
    list = fetchArrayVal(data, 'que:queueEntryState')
    list.each do |obj|
      q = QueueEntry.new(obj)
      next unless q.checkFilter(queueList.filter)
      qenrtylist = queueList.batches.fetch(q.bid, QueueBatch.new(q.bid, q.user))
      qenrtylist.addJob(q)
      queueList.batches[q.bid] = qenrtylist
      queueList.jobs.append(q)
    end
  end
end

class QueueList < MerrittJson
  def initialize(ingest_server, body, filter = "")
    super()
    @ingest_server = ingest_server
    @body = body
    @batches = {}
    @jobs = []
    @filter = filter
    retrieveQueues
  end

  def self.get_queue_list(ingest_server, filter = "")
    qjson = HttpGetJson.new(ingest_server, "admin/queues")
    QueueList.new(ingest_server, qjson.body, filter)
  end

  def retrieveQueues
    data = JSON.parse(@body)
    data = fetchHashVal(data, 'ingq:ingestQueueNameState')
    data = fetchHashVal(data, 'ingq:ingestQueueName')
    fetchArrayVal(data, 'ingq:ingestQueue').each do |qjson|
      node = fetchHashVal(qjson, 'ingq:node')
      begin
        qjson = HttpGetJson.new(@ingest_server, "admin/queue/#{node}")
        next unless qjson.status == 200
        IngestQueue.new(self, qjson.body)
      rescue => e
        puts(e.message)
        puts(e.backtrace)
      end
    end
  end

  def filter
    @filter
  end

  def body
    @body
  end

  def batches
    @batches
  end

  def jobs
    @jobs
  end

  def to_table
    table = []
    @jobs.each_with_index do |q, i|
      table.append(q.to_table_row)
    end
    table
  end

end

