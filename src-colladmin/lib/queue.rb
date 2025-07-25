# frozen_string_literal: true

require_relative 'queue_json'

# representation of an ingest queue entry
class QueueEntry < QueueJson
  @@placeholder = nil
  @@migration = :none
  def self.placeholder
    @@placeholder = QueueEntry.new({}) if @@placeholder.nil?
    @@placeholder
  end

  def initialize(json)
    # not yet used
    # {
    #  "queuePriority": "03",
    #  "responseForm": "xml",
    #  "localID": "2024_03_04_1717_v1file",
    #  "update": true
    # }

    super()

    # until July 2023, Merritt had 3 separate queues identified as a queue node
    add_property(
      :queueNode,
      MerrittJsonProperty.new('Ingest Worker').lookup_value(json, '', :queueNode)
    )
    add_property(
      :bid,
      MerrittJsonProperty.new('Batch').lookup_value(json, '', :batchID)
    )
    add_property(
      :job,
      MerrittJsonProperty.new('Job').lookup_value(json, '', :jobID)
    )
    add_property(
      :profile,
      MerrittJsonProperty.new('Profile').lookup_value(json, '', :profile)
    )
    # insert binary time field
    add_property(
      :date,
      MerrittJsonProperty.new('Date').lookup_time_value(json, '', :submissionDate,
        MerrittJsonProperty.new('Date').lookup_value(json, '', :date).value)
    )
    add_property(
      :user,
      MerrittJsonProperty.new('User').lookup_value(json, '', :submitter)
    )
    add_property(
      :title,
      MerrittJsonProperty.new('Title').lookup_value(json, '', :title)
    )
    add_property(
      :file_type,
      MerrittJsonProperty.new('File Type').lookup_value(json, '', :type)
    )
    # insert status from binary field
    add_property(
      :qstatus,
      MerrittJsonProperty.new('QStatus').lookup_value(json, '', :status)
    )
    add_property(
      :queue,
      MerrittJsonProperty.new('Name').lookup_value(json, '', :filename)
    )
    add_property(
      :queueId,
      MerrittJsonProperty.new('Queue ID').lookup_value(json, '', :id)
    )
    add_property(
      :priority,
      MerrittJsonProperty.new('Priority').lookup_value(json, '', :priority)
    )
    add_property(
      :space_needed,
      MerrittJsonProperty.new('Space Needed').lookup_value(json, '', :space_needed)
    )
    # extract the ingest worker node from the queue id string
    qid = get_value(:queueId, '')
    qnode = get_value(:queueNode, '')
    if qnode =~ %r{^/?ingest$} && qid =~ /^mrtQ-/
      set_property(:queueNode,
        MerrittJsonProperty.new('Ingest Worker', qid[8]))
    end

    qs = get_value(:qstatus, '')
    st = 'INFO'
    st = 'FAIL' if qs == 'Failed'
    st = 'PASS' if qs == 'Completed'
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
    add_property(
      :hold,
      MerrittJsonProperty.new('Hold', get_hold_path_m1)
    )
    add_property(
      :release,
      MerrittJsonProperty.new('Release', get_release_path_m1)
    )
  end

  def check_filter(filter)
    show = true
    fbatch = filter.fetch(:batch, '')
    show &&= fbatch.empty? || bid == fbatch
    fprofile = filter.fetch(:profile, '')
    show &&= fprofile.empty? || profile == fprofile
    fstatus = filter.fetch(:qstatus, '')
    show && (fstatus.empty? || qstatus == fstatus)
  end

  def self.table_headers
    QueueEntry.placeholder.get_property_list.map do |sym|
      QueueEntry.placeholder.get_label(sym)
    end
  end

  def self.table_types
    arr = []
    QueueEntry.placeholder.get_property_list.each do |sym|
      type = ''
      type = 'qbatch' if sym == :bid
      type = 'qjob' if sym == :job
      type = 'status' if sym == :status
      type = 'datetime' if sym == :date
      type = 'qdelete-mrtzk' if sym == :qdelete
      type = 'requeue-mrtzk' if sym == :requeue
      type = 'hold-mrtzk' if sym == :hold
      type = 'release-mrtzk' if sym == :release
      type = 'container' if sym == :queue
      type = 'zkjob' if sym == :queueId
      type = 'bytes' if sym == :space_needed
      arr.append(type)
    end
    arr
  end

  def to_table_row
    arr = []
    QueueEntry.placeholder.get_property_list.each do |sym|
      v = get_value(sym)
      v = "#{bid}/#{v}" if sym == :job
      arr.append(v)
    end
    arr
  end

  def queue_id
    get_value(:queueId)
  end

  def bid
    get_value(:bid)
  end

  def jid
    get_value(:job)
  end

  def profile
    get_value(:profile)
  end

  def status
    get_value(:status)
  end

  def qstatus
    get_value(:qstatus)
  end

  def user
    get_value(:user)
  end

  def title
    get_value(:title)
  end

  def file_type
    get_value(:file_type)
  end

  def date
    get_value(:date)
  end

  def get_queue_node
    '/jobs'
  end
end

## Queue representation of Batch objects
class BatchQueueEntry < QueueJson
  AGE_BATCHWARN = 3600 * 24

  @@placeholder = nil
  def self.placeholder
    @@placeholder = BatchQueueEntry.new({}) if @@placeholder.nil?
    @@placeholder
  end

  def initialize(json)
    super()

    # until July 2023, Merritt had 3 separate queues identified as a queue node
    add_property(
      :bid,
      MerrittJsonProperty.new('Batch').lookup_value(json, '', :batchID)
    )
    add_property(
      :job,
      MerrittJsonProperty.new('Job Count').lookup_value(json, '', :jobCount, 0)
    )
    add_property(
      :profile,
      MerrittJsonProperty.new('Profile').lookup_value(json, '', :profile, '')
    )
    # insert binary time field
    add_property(
      :date,
      MerrittJsonProperty.new('Date').lookup_time_value(json, '', :submissionDate,
        MerrittJsonProperty.new('Date').lookup_value(json, '', :date).value)
    )
    add_property(
      :user,
      MerrittJsonProperty.new('User').lookup_value(json, '', :submitter)
    )
    add_property(
      :title,
      MerrittJsonProperty.new('Title').lookup_value(json, '', :title)
    )
    add_property(
      :file_type,
      MerrittJsonProperty.new('File Type').lookup_value(json, '', :type)
    )
    # insert status from binary field
    add_property(
      :qstatus,
      MerrittJsonProperty.new('QStatus').lookup_value(json, '', :status)
    )
    add_property(
      :queue,
      MerrittJsonProperty.new('Name').lookup_value(json, '', :filename)
    )
    add_property(
      :queueId,
      MerrittJsonProperty.new('Queue ID').lookup_value(json, '', :id)
    )

    qs = get_value(:qstatus, '')
    st = 'INFO'
    begin
      st = 'WARN' if Time.now - get_value(:date, Time.now) > AGE_BATCHWARN
    rescue StandardError => e
      puts "Error processing submission date #{e}"
    end
    st = 'FAIL' if qs == 'Failed'
    st = 'PASS' if qs == 'Completed'
    add_property(
      :status,
      MerrittJsonProperty.new('Status', st)
    )

    add_property(
      :qdelete,
      MerrittJsonProperty.new('Queue Del', get_del_batch_path)
    )
    add_property(
      :requeue,
      MerrittJsonProperty.new('Update Reporting', get_update_batch_path)
    )
  end

  def self.table_headers
    BatchQueueEntry.placeholder.get_property_list.map do |sym|
      BatchQueueEntry.placeholder.get_label(sym)
    end
  end

  def self.table_types
    arr = []
    BatchQueueEntry.placeholder.get_property_list.each do |sym|
      type = ''
      type = 'fbatch' if sym == :bid
      type = 'status' if sym == :status
      type = 'datetime' if sym == :date
      type = 'qdelete-batch-mrtzk' if sym == :qdelete
      type = 'update-batch-mrtzk' if sym == :requeue
      type = 'container' if sym == :queue
      type = 'zkbatch' if sym == :queueId
      arr.append(type)
    end
    arr
  end

  def to_table_row
    arr = []
    BatchQueueEntry.placeholder.get_property_list.each do |sym|
      v = get_value(sym)
      arr.append(v)
    end
    arr
  end

  def queue_id
    get_value(:queueId)
  end

  def bid
    get_value(:bid)
  end

  def profile
    get_value(:profile)
  end

  def status
    get_value(:status)
  end

  def qstatus
    get_value(:qstatus)
  end

  def user
    get_value(:user)
  end

  def title
    get_value(:title)
  end

  def file_type
    get_value(:file_type)
  end

  def date
    get_value(:date)
  end
end

# representation of a merritt ingest batch (a batch contains multiple jobs)
class QueueBatch < MerrittJson
  def initialize(bid, submitter)
    @bid = bid
    @submitter = submitter
    @jobs = []
    super()
  end

  def add_job(qj)
    @jobs.append(qj)
  end

  attr_reader :bid, :submitter

  def num_jobs
    @jobs.length
  end
end

# List of queues of a particular type - ingest once had separate queues for each worker
class QueueList < MerrittJson
  def initialize(zk, filter = {})
    super()
    @batches = {}
    @jobs = []
    @profiles = {}
    @filter = filter
    jobs = MerrittZK::Job.list_jobs_as_json(zk)
    jobs.each do |j|
      job = QueueEntry.new(j)
      next if @filter.key?(:batch) && job.bid != @filter[:batch]
      next if @filter.fetch(:deletable, false) && !%w[Completed Deleted].include?(job.qstatus)
      next if @filter.fetch(:held, false) && !%w[Held].include?(job.qstatus)

      @jobs << job
      qb = @batches.fetch(job.bid, QueueBatch.new(job.bid, job.user))
      qb.add_job(job)
      @batches[job.bid] = qb

      k = "#{job.profile},#{job.qstatus}"
      profiles[k] = profiles.fetch(k, [])
      profiles[k].append(job)
    end
  end

  attr_reader :filter, :body, :batches, :profiles, :jobs

  def to_table
    table = []
    js = @jobs.sort do |a, b|
      if a.status == b.status
        b.date <=> a.date
      else
        AdminTask.status_sort_val(a.status) <=> AdminTask.status_sort_val(b.status)
      end
    end
    js.each_with_index do |q, _i|
      table.append(q.to_table_row)
    end
    table
  end
end
