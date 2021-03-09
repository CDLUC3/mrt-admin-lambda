require_relative 'action'
require_relative 'forward_to_ingest_action'
require_relative '../lib/queue'

class IngestBatchAction < ForwardToIngestAction
  def initialize(config, path, myparams)
    @batch = myparams.fetch('batch', '')
    super(config, path, myparams, "admin/queues")
  end

  def get_title
    "Ingest Batches #{@batch}"
  end

  def table_headers
    if @batch.empty?
      Batch.table_headers
    else
      QueueEntry.table_headers
    end
  end

  def table_types
    if @batch.empty?
      Batch.table_types
    else
      QueueEntry.table_types
    end
  end

  def table_rows(body)
    queueList = QueueList.new(body, @batch)
    if @batch.empty?
      queueList.to_table_batches
    else
      queueList.to_table_jobs
    end
  end

  def hasTable
    true
  end

end
