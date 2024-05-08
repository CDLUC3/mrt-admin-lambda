# frozen_string_literal: true

require_relative 'forward_to_ingest_action'

# Collection Admin Task class - see config/actions.yml for description
class IngestBatchFoldersAction < ForwardToIngestAction
  def initialize(config, action, path, myparams)
    @days = myparams.fetch('days', '7').to_i
    @days = 60 if @days > 60
    super(config, action, path, myparams, "admin/bids/#{@days}")
    @zk = ZK.new(get_zookeeper_conn)
    ZookeeperListAction.migration_level(@zk)
  end

  def get_zookeeper_conn
    @config.fetch('zookeeper', '')
  end

  def get_title
    "Batch Folders - Last #{@days} days"
  end

  def table_headers
    BatchFolder.table_headers
  end

  def table_types
    BatchFolder.table_types
  end

  def init_status
    :PASS
  end

  def table_rows(body)
    bflist = BatchFolderList.new(body)
    bflist.apply_queue_list(QueueList.new(@zk))
    bflist.apply_recent_ingests(RecentIngests.new(@config, @days))
    bflist.to_table
  end

  def has_table
    true
  end

  def get_alternative_queries
    [
      {
        label: 'Batch Folders Last 7 days',
        url: "#{LambdaBase.colladmin_url}?path=batchFolders&days=7",
        class: 'batches'
      },
      {
        label: 'Batch Folders Last 14 days',
        url: "#{LambdaBase.colladmin_url}?path=batchFolders&days=14",
        class: 'batches'
      },
      {
        label: 'Batch Folders Last 21 days',
        url: "#{LambdaBase.colladmin_url}?path=batchFolders&days=21",
        class: 'batches'
      }
    ]
  end

  def page_size
    500
  end
end

# folder on an ingest folder
class BatchFolder < MerrittJson
  def initialize(bid, dtime)
    super()
    @bid = bid
    @dtime = dtime
    @qbid = ''
    @qsubmitter = ''
    @dbobj = ''
    @dbprofile = ''
    @dbuser = ''
  end

  def table_row
    [
      @bid,
      @dtime,
      @qbid,
      @qsubmitter,
      @dbobj,
      @dbprofile,
      @dbuser,
      status
    ]
  end

  def self.table_headers
    [
      'Batch',
      'Date',
      'Queue Jobs',
      'Queue Submitter',
      'DB Obj Cnt',
      'DB Profile',
      'DB User',
      'Status'
    ]
  end

  def self.table_types
    [
      'qbatch',
      '',
      'qbatchnote',
      '',
      'batchnote',
      '',
      '',
      'status'
    ]
  end

  def status
    return 'PASS' unless @dbobj.empty?
    return 'FAIL' if DateTime.parse(@dtime) < DateTime.now.next_day(-1)
    return 'WARN' if DateTime.parse(@dtime).to_time < (Time.now - 3600)

    'PASS'
  end

  attr_reader :dtime, :bid

  def set_queue_item(batch)
    @qbid = "#{batch.bid}; #{batch.num_jobs}"
    @qsubmitter = batch.submitter
  end

  def set_recent_item(recentbatch)
    @dbobj = recentbatch.dbobj
    @dbprofile = recentbatch.dbprofile
    @dbuser = recentbatch.dbuser
  end
end

# list of ingest batch folders
class BatchFolderList < MerrittJson
  def initialize(body)
    super()
    @batch_folders = []
    @batch_folder_hash = {}
    data = JSON.parse(body)
    data = fetch_hash_val(data, 'fil:batchFileState')
    data = fetch_hash_val(data, 'fil:jobFile')
    list = fetch_array_val(data, 'fil:batchFile')
    list.each do |obj|
      bf = BatchFolder.new(
        obj.fetch('fil:file', ''),
        obj.fetch('fil:fileDate', '')
      )
      @batch_folders.append(
        bf
      )
      @batch_folder_hash[bf.bid] = bf
    end
  end

  def empty?
    @batch_folders.empty?
  end

  def to_table
    bfs = @batch_folders.sort do |a, b|
      if a.status == b.status
        b.dtime <=> a.dtime
      else
        AdminTask.status_sort_val(a.status) <=> AdminTask.status_sort_val(b.status)
      end
    end
    bfs.map(&:table_row)
  end

  def apply_queue_list(queue_list)
    return if @batch_folder_hash.empty?

    queue_list.batches.each do |bid, qbatch|
      @batch_folder_hash[bid].set_queue_item(qbatch) if @batch_folder_hash.key?(bid)
    end
  end

  def apply_recent_ingests(recentitems)
    return if @batch_folder_hash.empty?

    recentitems.batches.each do |bid, recentbatch|
      @batch_folder_hash[bid].set_recent_item(recentbatch) if @batch_folder_hash.key?(bid)
    end
  end
end

# recent ingest job
class RecentIngest
  def initialize(row)
    @bid = row[0]
    @profile = row[1]
    @submitted = row[2]
    @dbuser = row[3]
    @object_cnt = row[4]
  end

  attr_reader :bid, :profile, :submitted, :object_cnt, :dbuser

  def dbobj
    "#{@bid}; #{@object_cnt}"
  end

  def dbprofile
    @profile
  end
end

# recent ingest jobs
class RecentIngests < MerrittQuery
  def initialize(config, days = 14)
    super(config)
    @batches = {}
    run_query(
      %{
              select
                  batch_id,
                  max(profile),
                  max(submitted),
                  max(user_agent),
                  count(*)
              from
                  inv_ingests
              where
                  submitted > date_add(date(now()), INTERVAL -? DAY)
              group by
                  batch_id
              ;
          },
      [days + 7]
    ).each do |r|
      ri = RecentIngest.new(r)
      @batches[ri.bid] = ri
    end
  end

  attr_reader :batches
end
