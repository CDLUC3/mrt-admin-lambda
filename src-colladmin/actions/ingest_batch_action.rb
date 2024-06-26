# frozen_string_literal: true

require_relative 'forward_to_ingest_action'

# Collection Admin Task class - see config/actions.yml for description
class IngestBatchAction < ZookeeperListAction
  def initialize(config, action, path, myparams)
    @batch = myparams.fetch('batch', 'no-batch-provided')
    @batch_obj = Batch.new(@batch)
    super(config, action, path, myparams, { batch: @batch })
  end

  def get_title
    "Ingest Batches #{@batch}"
  end

  def table_headers
    @batch_obj.table_headers
  end

  def table_types
    @batch_obj.table_types
  end

  def table_rows(_body)
    queue_list = QueueList.new(@zk, { batch: @batch })
    queue_list.jobs.each do |qe|
      @batch_obj.add_queue_job(qe)
    end
    dbjob = RecentBatchIngests.new(@config, @batch)
    dbjob.jobs.each_value do |dj|
      @batch_obj.add_db_job(dj)
    end
    @batch_obj.to_table
  end

  def has_table
    true
  end
end

# job within an ingest batch
class BatchJob < MerrittJson
  def initialize(bid, jid)
    @bid = bid
    @jid = jid
    @status = ''
    @qstatus = ''
    @submitter = ''
    @title = ''
    @date = ''
    @file_type = ''
    @profile = ''
    @obj_cnt = ''
    super()
  end

  def read_queue_object(qe)
    @qstatus = qe.qstatus
    @status = qe.status
    @submitter = qe.user
    @title = qe.title
    @date = qe.date
    @file_type = qe.file_type
    @profile = qe.profile
  end

  def read_db_job(dj)
    @obj_cnt = dj.obj_cnt
    @date = dj.date
    @profile = dj.profile
    @submitter = dj.user
    @file_type = dj.file_type
  end

  def self.table_headers
    [
      'Job Id',
      'Ingest Status',
      'Submitter',
      'Title',
      'Date',
      'File Type',
      'Profile',
      'DB Obj Cnt',
      'Status'
    ]
  end

  def self.table_types
    [
      'qjob',
      '',
      '',
      '',
      '',
      '',
      '',
      'jobnote',
      'status'
    ]
  end

  def status
    return @status unless @status.empty? || @status.nil?
    return 'PASS' if @obj_cnt.positive?

    'INFO'
  end

  def to_table_row
    [
      "#{@bid}/#{@jid}",
      @qstatus,
      @submitter,
      @title,
      @date,
      @file_type,
      @profile,
      "#{@bid}/#{@jid}; #{@obj_cnt}",
      status
    ]
  end
end

# contains the jobs associated with an ingest batch
class Batch < MerrittJson
  def initialize(bid)
    super()
    @bid = bid
    @jobs = {}
  end

  def add_queue_job(qe)
    job = @jobs.fetch(qe.jid, BatchJob.new(@bid, qe.jid))
    job.read_queue_object(qe)
    @jobs[qe.jid] = job
  end

  def add_db_job(dj)
    job = @jobs.fetch(dj.jid, BatchJob.new(@bid, dj.jid))
    job.read_db_job(dj)
    @jobs[dj.jid] = job
  end

  attr_reader :bid

  def table_headers
    BatchJob.table_headers
  end

  def table_types
    BatchJob.table_types
  end

  def to_table
    table = []
    @jobs.each_value do |job|
      table.append(job.to_table_row)
    end
    table
  end
end

# batch recently ingested
class RecentBatchIngest
  def initialize(row)
    @bid = row[0]
    @jid = row[1]
    @profile = row[2]
    @date = row[3]
    @user = row[4]
    @file_type = row[5]
    @obj_cnt = row[6]
  end

  attr_reader :bid, :jid, :profile, :date, :user, :file_type, :obj_cnt
end

# recent batches ingested
class RecentBatchIngests < MerrittQuery
  def initialize(config, bid)
    super(config)
    bid = '' if bid == 'JOB_ONLY'
    @jobs = {}
    run_query(
      %{
              select
                  batch_id,
                  job_id,
                  max(profile),
                  max(submitted),
                  max(user_agent),
                  max(ingest_type),
                  count(*)
              from
                  inv_ingests
              where
                  batch_id = ?
              group by
                  batch_id,
                  job_id
              ;
          },
      [bid]
    ).each do |r|
      ri = RecentBatchIngest.new(r)
      @jobs[ri.jid] = ri
    end
  end

  attr_reader :jobs
end
