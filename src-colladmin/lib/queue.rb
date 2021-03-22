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
      :tilte, 
      MerrittJsonProperty.new("Title").lookupValue(json, "que", "objectTitle")
    )
    addProperty(
      :fileType, 
      MerrittJsonProperty.new("File Type").lookupValue(json, "que", "fileType")
    )
    addProperty(
      :status, 
      MerrittJsonProperty.new("Status").lookupValue(json, "que", "status")
    )
    addProperty(
      :queue, 
      MerrittJsonProperty.new("Name").lookupValue(json, "que", "name")
    )
    addProperty(
      :queueId, 
      MerrittJsonProperty.new("Queue ID").lookupValue(json, "que", "iD")
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

  def job
    getValue(:job)
  end

  def status
    getValue(:status)
  end
end

class Batch < MerrittJson
  def initialize(bid, submitter)
    super()
    @bid = bid
    @submitter = submitter
    @jobs = []
    @statuses = {}
  end

  def addJob(job)
    @jobs.append(job)
    @statuses[job.status] = @statuses.fetch(job.status, 0) + 1
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

  def num_jobs_by_status(status)
    @statuses.fetch(status, 0)
  end

  def self.table_headers
    [
      'Batch Id',
      'Submitter',
      'Num Jobs',
      'Num Compeleted',
      'Num Consumed',
      'Num Failed',
      'Num Pending'
    ]
  end

  def self.table_types
    [
      'qbatch',
      '',
      '',
      '',
      '',
      '',
      ''
    ]
  end

  def to_table_row
    [
      @bid,
      @submitter,
      num_jobs,
      num_jobs_by_status("Completed"),
      num_jobs_by_status("Consumed"),
      num_jobs_by_status("Failed"),
      num_jobs_by_status("Pending")
    ]
  end

  def to_table
    table = []
    @jobs.each do |job|
      table.append(job.to_table_row)
    end
    table
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
      qenrtylist = queueList.batches.fetch(q.bid, Batch.new(q.bid, q.getValue(:user)))
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

  def self.get_queue_list(ingest_server)
    qjson = HttpGetJson.new(ingest_server, "admin/queues")
    QueueList.new(ingest_server, qjson.body)
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

  def to_table_batches
    table = []
    @batches.each do |bid,b|
      table.append(b.to_table_row)
    end
    table
  end

  def to_table_jobs
    table = []
    @jobs.each do |q|
      table.append(q.to_table_row)
    end
    table
  end
end

class Job < MerrittJson
  def initialize(jid, dtime)
    super()
    @jid = jid;
    @dtime = dtime
  end

  def table_row
    [
      "JOB_ONLY/#{@jid}",
      @dtime
    ]
  end

  def dtime
    @dtime
  end
end

class JobList < MerrittJson
  def initialize(body)
    super()
    @jobs = []
    data = JSON.parse(body)
    data = fetchHashVal(data, 'fil:batchFileState')
    data = fetchHashVal(data, 'fil:jobFile')
    list = fetchArrayVal(data, 'fil:batchFile')
    list.each do |obj|
      @jobs.append(
        Job.new(
          obj.fetch('fil:file', ''),
          obj.fetch('fil:fileDate', '')
        )
      )
    end
  end

  def to_table
    table = []
    @jobs.sort {
      # reverse sort on date
      |a,b| b.dtime <=> a.dtime
    }.each do |job|
      table.append(job.table_row)
    end
    table
  end
end

class BatchFolder < MerrittJson
  def initialize(bid, dtime)
    super()
    @bid = bid;
    @dtime = dtime
    @qbid = ""
  end

  def table_row
    [
      @bid,
      @dtime,
      @qbid
    ]
  end

  def dtime
    @dtime
  end

  def bid
    @bid
  end

  def setQueueItem(batch)
    @qbid = "#{batch.bid}; #{batch.num_jobs} Jobs - Submitter: #{batch.submitter}"
  end
end

class BatchFolderList < MerrittJson
  def initialize(body)
    super()
    @batchFolders = []
    @batchFolderHash = {}
    data = JSON.parse(body)
    data = fetchHashVal(data, 'fil:batchFileState')
    data = fetchHashVal(data, 'fil:jobFile')
    list = fetchArrayVal(data, 'fil:batchFile')
    list.each do |obj|
      bf = BatchFolder.new(
        obj.fetch('fil:file', ''),
        obj.fetch('fil:fileDate', '')
      )
      @batchFolders.append(
        bf
      )
      @batchFolderHash[bf.bid] = bf
    end
  end

  def to_table
    table = []
    @batchFolders.sort {
      # reverse sort on date
      |a,b| b.dtime <=> a.dtime
    }.each do |bf|
      table.append(bf.table_row)
    end
    table
  end

  def apply_queue_list(queue_list)
    queue_list.batches.each do |bid, qbatch|
      if @batchFolderHash.key?(bid)
        @batchFolderHash[bid].setQueueItem(qbatch)
      end
    end
  end
end

class JobManifestEntry < MerrittJson
  @@placeholder = nil
  def self.placeholder
    @@placeholder = JobManifestEntry.new({}) if @@placeholder.nil?
    @@placeholder
  end

  def initialize(json)
    super()
    addProperty(
      :fileSize, 
      MerrittJsonProperty.new("File Size").lookupValue(json, "ingmans", "fileSize")
    )
    addProperty(
      :mimeType, 
      MerrittJsonProperty.new("Mime Type").lookupValue(json, "ingmans", "mimeType")
    )
    addProperty(
      :fileName, 
      MerrittJsonProperty.new("File Name").lookupValue(json, "ingmans", "fileName")
    )
    addProperty(
      :hashValue, 
      MerrittJsonProperty.new("Hash Value").lookupValue(json, "ingmans", "hashValue")
    )
    addProperty(
      :hashAlgorithm, 
      MerrittJsonProperty.new("Hash Algorithm").lookupValue(json, "ingmans", "hashAlgorithm")
    )
  end

  def self.table_headers
    arr = []
    JobManifestEntry.placeholder.getPropertyList.each do |sym|
      arr.append(JobManifestEntry.placeholder.getLabel(sym))
    end
    arr
  end

  def self.table_types
    arr = []
    JobManifestEntry.placeholder.getPropertyList.each do |sym|
      type = ''
      type = 'bytes' if sym == :fileSize
      arr.append(type)
    end
    arr
  end

  def to_table_row
    arr = []
    JobManifestEntry.placeholder.getPropertyList.each do |sym|
      v = getValue(sym)
      arr.append(v)
    end
    arr
  end
end


class JobManifest < MerrittJson
  def initialize(body)
    super()
    @entries = []
    data = JSON.parse(body)
    data = fetchHashVal(data, 'ingmans:manifestsState')
    data = fetchHashVal(data, 'ingmans:manifests')
    list = fetchArrayVal(data, 'ingmans:manifestEntryState')
    list.each do |obj|
      @entries.append(JobManifestEntry.new(obj))
    end
  end

  def to_table
    table = []
    @entries.each_with_index do |jme, i|
      break if (i >= 5000) 
      table.append(jme.to_table_row)
    end
    table
  end
end
      