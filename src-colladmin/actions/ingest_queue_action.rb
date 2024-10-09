# frozen_string_literal: true

require_relative 'zookeeper_action'

# Collection Admin Task class - see config/actions.yml for description
class IngestQueueAction < IngestQueueZookeeperAction
  def initialize(config, action, path, myparams)
    @batch = myparams.fetch('batch', '')
    @profile = myparams.fetch('profile', '')
    @qstatus = myparams.fetch('qstatus', '')
    @filter = {
      batch: @batch,
      profile: @profile,
      qstatus: @qstatus
    }
    super(config, action, path, myparams, @filter)
    @batches = {}
  end

  def filter_batch
    @filter.fetch(:batch, '')
  end

  def filter_profile
    @filter.fetch(:profile, '')
  end

  def filter_qstatus
    @filter.fetch(:qstatus, '')
  end

  def register_item(item)
    return unless filter_batch.empty? || filter_batch == item.bid
    return unless filter_profile.empty? || filter_profile == item.profile
    return unless filter_qstatus.empty? || filter_qstatus == item.qstatus

    super
  end

  def get_title
    'List Ingest Queues'
  end

  def table_headers
    QueueEntry.table_headers
  end

  def table_types
    QueueEntry.table_types
  end

  def has_table
    true
  end

  def init_status
    return :PASS if @batch.empty? && @profile.empty? && @qstatus.empty?

    :SKIP
  end

  def get_alternative_queries
    arr = [
      {
        label: 'Ingest Queue Counts by Profile',
        url: "#{LambdaBase.colladmin_url}?path=ingest-queue-by-profile",
        class: 'graph'
      },
      {
        label: 'Requeue All',
        url: '',
        class: 'action requeue-all'
      },
      {
        label: 'Delete All',
        url: '',
        class: 'action deleteq-all'
      },
      {
        label: 'Cleanup Queue',
        url: "#{LambdaBase.colladmin_url}?path=cleanup-queue&queue=queues&reload_path=queues",
        class: 'action'
      }
    ]
    if @batch.empty?
      @batches.each do |k, qb|
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

# Collection Admin Task class - see config/actions.yml for description
class BatchIngestQueueAction < IngestBatchQueueZookeeperAction
  def initialize(config, action, path, myparams)
    super
    @batches = {}
  end

  def get_title
    'List Ingest Batches'
  end

  def table_headers
    BatchQueueEntry.table_headers
  end

  def table_types
    BatchQueueEntry.table_types
  end

  def has_table
    true
  end

  def init_status
    :PASS
  end

  def get_alternative_queries
    [
      {
        label: 'Ingest Queue Counts by Profile and Batch',
        url: "#{LambdaBase.colladmin_url}?path=ingest-queue-by-profile-batch",
        class: 'graph'
      }
    ]
  end

  def page_size
    100
  end
end
