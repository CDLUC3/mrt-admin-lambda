require_relative 'forward_to_ingest_action'

class IngestBatchFoldersAction < ForwardToIngestAction
  def initialize(config, path, myparams)
    @days = myparams.fetch("days", "7").to_i 
    @days = 60 if @days > 60
    super(config, path, myparams, "admin/bids/#{@days}")
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

  def table_rows(body)
    bflist = BatchFolderList.new(body)
    bflist.apply_queue_list(QueueList.get_queue_list(get_ingest_server))
    bflist.apply_recent_ingests(RecentIngests.new(@config, @days))
    bflist.to_table
  end

  def hasTable
    true
  end

  def get_alternative_queries
    [
      {
        label: 'Batch Folders Last 7 days', 
        url: "path=batchFolders&days=7"
      },
      {
        label: 'Batch Folders Last 14 days', 
        url: "path=batchFolders&days=14"
      },
      {
        label: 'Batch Folders Last 21 days', 
        url: "path=batchFolders&days=21"
      }
    ]
  end

end

class BatchFolder < MerrittJson
  def initialize(bid, dtime)
    super()
    @bid = bid;
    @dtime = dtime
    @qbid = ""
    @qsubmitter = ''
    @dbobj = ""
    @dbprofile = ""
    @dbuser = ""
  end

  def table_row
    [
      @bid,
      @dtime,
      @qbid,
      @qsubmitter,
      @dbobj,
      @dbprofile,
      @dbuser
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
      'DB User'
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
      ''
    ]
  end

  def dtime
    @dtime
  end

  def bid
    @bid
  end

  def setQueueItem(batch)
    @qbid = "#{batch.bid}; #{batch.num_jobs}"
    @qsubmitter = batch.submitter
  end

  def setRecentItem(recentbatch)
    @dbobj = recentbatch.dbobj
    @dbprofile = recentbatch.dbprofile
    @dbuser = recentbatch.dbuser
  end
end

class BatchFolderList < MerrittJson
  def initialize(body)
    super()
    @batchFolders = []
    @batchFolderHash = {}
    data = JSON.parse(body)
    data = fetchHashVal(data, 'fil:batchFileState')
    data = fetchHashVal(data, 'fil:jobFile')
    list = fetchArrayVal(data, 'fil:batchFile')
    list.each do |obj|
      bf = BatchFolder.new(
        obj.fetch('fil:file', ''),
        obj.fetch('fil:fileDate', '')
      )
      @batchFolders.append(
        bf
      )
      @batchFolderHash[bf.bid] = bf
    end
  end

  def to_table
    table = []
    @batchFolders.sort {
      # reverse sort on date
      |a,b| b.dtime <=> a.dtime
    }.each do |bf|
      table.append(bf.table_row)
    end
    table
  end

  def apply_queue_list(queue_list)
    queue_list.batches.each do |bid, qbatch|
      if @batchFolderHash.key?(bid)
        @batchFolderHash[bid].setQueueItem(qbatch)
      end
    end
  end

  def apply_recent_ingests(recentitems)
    recentitems.batches.each do |bid, recentbatch|
      if @batchFolderHash.key?(bid)
        @batchFolderHash[bid].setRecentItem(recentbatch)
      end
    end
  end
end

class RecentIngest < QueryObject
  def initialize(row)
      @bid = row[0]
      @profile = row[1]
      @submitted = row[2]
      @dbuser = row[3]
      @object_cnt = row[4]
  end

  def bid
      @bid
  end

  def profile
      @profile
  end
  
  def submitted
      @submitted
  end

  def object_cnt
      @object_cnt
  end

  def dbobj
      "#{@bid}; #{@object_cnt}"
  end

  def dbprofile
    @profile
  end

  def dbuser
    @dbuser
  end
end


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
          [days]
      ).each do |r|
          ri = RecentIngest.new(r)
          @batches[ri.bid] = ri
      end
  end

  def batches
      @batches
  end
end
