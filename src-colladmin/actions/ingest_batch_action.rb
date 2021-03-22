require_relative 'forward_to_ingest_action'

class IngestBatchAction < ForwardToIngestAction
  def initialize(config, path, myparams)
    @batch = myparams.fetch('batch', '')
    super(config, path, myparams, "admin/queues")
  end

  def get_title
    "Ingest Batches #{@batch}"
  end

  def table_headers
    Batch.table_headers
  end

  def table_types
    Batch.table_types
  end

  def table_rows(body)
    queueList = QueueList.new(get_ingest_server, body, @batch)
    queueList.to_table_batches
  end

  def hasTable
    true
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
