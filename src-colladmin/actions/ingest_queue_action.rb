require_relative 'forward_to_ingest_action'

class IngestQueueAction < ForwardToIngestAction
  def initialize(config, action, path, myparams)
    super(config, action, path, myparams, 'admin/queues')
    @batch = myparams.fetch("batch", "")
    @profile = myparams.fetch("profile", "")
    @qstatus = myparams.fetch("qstatus", "")
    @filter = {
      batch: @batch,
      profile: @profile,
      qstatus: @qstatus,
    }
    @batches = {}
  end

  def get_title
    "List Ingest Queues"
  end

  def table_headers
    QueueEntry.table_headers
  end

  def table_types
    QueueEntry.table_types
  end

  def table_rows(body)
    queueList = QueueList.new(get_ingest_server, body, @filter)
    @batches = queueList.batches
    queueList.to_table
  end

  def hasTable
    true
  end

  def init_status
    :PASS
  end

  def get_alternative_queries
    arr = [
      {
        label: 'Ingest Queue Counts by Profile', 
        url: "#{LambdaBase.colladmin_url}?path=ingest-queue-by-profile"
      }
    ]
    if @batch.empty?
      @batches.each do |k,qb|
        arr.append({
          label: "Batch #{k}: #{qb.num_jobs} Jobs",
          url: "#{LambdaBase.colladmin_url}?path=queues&profile=#{@profile}&qstatus=#{@qstatus}&batch=#{k}"
        })
      end
    end
    arr.append(
      {
        label: 'Completed Ingests', 
        url: "#{LambdaBase.admintool_url}?path=recent_ingests"
      }
    )
    arr
  end

  def page_size
    100
  end

end
