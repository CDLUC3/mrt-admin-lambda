require_relative 'forward_to_ingest_action'

class IngestBatchAction < ForwardToIngestAction
  def initialize(config, path, myparams)
    @batch = myparams.fetch('batch', 'no-batch-provided')
    @batch_obj = Batch.new(@batch)
    super(config, path, myparams, "admin/queues")
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

  def table_rows(body)
    queueList = QueueList.new(get_ingest_server, body, @batch)
    queueList.jobs.each do |qe|
      @batch_obj.add_queue_job(qe)
    end
    dbjob = RecentBatchIngests.new(@config, @batch)
    dbjob.jobs.each do |jid, dj|
      @batch_obj.add_db_job(dj)
    end
    @batch_obj.to_table
  end

  def hasTable
    true
  end

end

class BatchJob < MerrittJson
  def initialize(bid, jid)
    @bid = bid
    @jid = jid
    @status = ""
    @submitter = ""
    @title = ""
    @date = ""
    @fileType = ""
    @profile = ""
    @obj_cnt = ""
  end

  def read_queue_object(qe)
    @status = qe.status
    @submitter = qe.user
    @title = qe.title
    @date = qe.date
    @fileType = qe.fileType
    @profile = qe.profile
  end

  def read_db_job(dj)
    @obj_cnt = dj.obj_cnt
    @date = dj.date
    @profile = dj.profile
    @submitter = dj.user
    @fileType = dj.fileType

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
      'DB Obj Cnt'
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
      'jobnote'
    ]
  end

  def to_table_row
    [
      "#{@bid}/#{@jid}",
      @status,
      @submitter,
      @title,
      @date,
      @fileType,
      @profile,
      "#{@bid}/#{@jid}; #{@obj_cnt}" 
    ]
  end

end

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

  def bid
    @bid
  end

  def table_headers
    BatchJob.table_headers
  end

  def table_types
    BatchJob.table_types
  end

  def to_table
    table = []
    @jobs.each do |jid, job|
      table.append(job.to_table_row)
    end
    table
  end
end

class RecentBatchIngest < QueryObject
  def initialize(row)
      @bid = row[0]
      @jid = row[1]
      @profile = row[2]
      @date = row[3]
      @user = row[4]
      @fileType = row[5]
      @obj_cnt = row[6]
  end

  def bid
      @bid
  end

  def jid
      @jid
  end

  def profile
      @profile
  end
  
  def date
      @date
  end

  def user
      @user
  end

  def fileType
    @fileType
  end

  def obj_cnt
      @obj_cnt
  end
end

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

  def jobs
      @jobs
  end
end


