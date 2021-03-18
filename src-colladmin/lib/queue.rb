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
  def initialize(bid)
    super()
    @bid = bid
    @jobs = []
    @statuses = {}
  end

  def addJob(job)
    @jobs.append(job)
    @statuses[job.status] = @statuses.fetch(job.status, 0) + 1
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
      'Num Jobs',
      'Num Compeleted',
      'Num Consumed',
      'Num Failed'
    ]
  end

  def self.table_types
    [
      'qbatch',
      '',
      '',
      '',
      ''
    ]
  end

  def to_table_row
    [
      @bid,
      num_jobs,
      num_jobs_by_status("Completed"),
      num_jobs_by_status("Consumed"),
      num_jobs_by_status("Failed")
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
      puts(q)
      qenrtylist = queueList.batches.fetch(q.bid, Batch.new(q.bid))
      qenrtylist.addJob(q)
      queueList.batches[q.bid] = qenrtylist
      queueList.jobs.append(q)
    end
  end
end

class QueueList < MerrittJson
  def initialize(body, filter = "")
    super()
    @body = body
    @batches = {}
    @jobs = []
    @filter = filter
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
    @jobs.each do |job|
      table.append(job.table_row)
    end
    table
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
      