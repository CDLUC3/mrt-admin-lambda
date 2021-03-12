require_relative 'merritt_json'
class QueueEntry < MerrittJson
  def initialize(obj)
    super()
    @bid = obj.fetch('que:batchID', '')
    @job = obj.fetch('que:jobID', '')
    @profile = obj.fetch('que:profile', '')
    @date = obj.fetch('que:date', '')
    @user = obj.fetch('que:user', '')
    @title = obj.fetch('que:objectTitle', '')
    @fileType = obj.fetch('que:fileType', '')
    @status = obj.fetch('que:status', '')
    @queue = obj.fetch('que:name', '')
    @queueId = obj.fetch('que:iD', '')
  end

  def checkFilter(filter)
    filter.empty? || @bid == filter
  end

  def self.table_headers
    [
      'Batch',
      'Job',
      'Profile',
      'Date',
      'User',
      'Title',
      'Type',
      'Status',
      'Name',
      'Queue Id'
    ]
  end

  def self.table_types
    [
      'qbatch',
      'qjob',
      '',
      '',
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
      "#{@bid}/#{@job}",
      @profile,
      @date,
      @user,
      @title,
      @fileType,
      @status,
      @queue,
      @queueId
    ]
  end

  def bid
    @bid
  end

  def job
    @job
  end

  def status
    @status
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

class QueueList < MerrittJson
  def initialize(body, filter = "")
    super()
    @batches = {}
    @jobs = []
    data = JSON.parse(body)
    data = fetchHashVal(data, 'que:queueState')
    data = fetchHashVal(data, 'que:queueEntries')
    list = fetchArrayVal(data, 'que:queueEntryState')
    list.each do |obj|
      q = QueueEntry.new(obj)
      next unless q.checkFilter(filter)
      qlist = @batches.fetch(q.bid, Batch.new(q.bid))
      qlist.addJob(q)
      @batches[q.bid] = qlist
      @jobs.append(q)
    end
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

class JobList < MerrittJson
  def initialize(body)
    super()
    @jobs = []
    data = JSON.parse(body)
    data = fetchHashVal(data, 'fil:batchFileState')
    data = fetchHashVal(data, 'fil:jobFile')
    list = fetchArrayVal(data, 'fil:batchFile')
    list.each do |obj|
      @jobs.append(obj.fetch('fil:file', ''))
    end
  end

  def to_table
    table = []
    @jobs.each do |q|
      table.append(["JOB_ONLY/#{q}"])
    end
    table
  end
end