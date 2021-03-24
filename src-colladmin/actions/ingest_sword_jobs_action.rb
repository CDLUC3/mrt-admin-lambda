require_relative 'forward_to_ingest_action'

class IngestSwordJobsAction < ForwardToIngestAction
  def initialize(config, path, myparams)
    @days = myparams.fetch("days", "7").to_i 
    @days = 7 if @days > 7
    super(config, path, myparams, "admin/bid/JOB_ONLY")
  end

  def get_title
    "Sword Jobs"
  end

  def table_headers
    Job.table_headers
  end

  def table_types
    Job.table_types
  end

  def table_rows(body)
    jlist = JobList.new(body)
    recent = RecentSwordIngests.new(@config, @days)
    jlist.apply_recent_ingests(recent)
    jlist.to_table
  end

  def hasTable
    true
  end

end

class Job < MerrittJson
  def initialize(jid, dtime)
    super()
    @jid = jid.strip
    @dtime = dtime
    @dbobj = ""
    @dbprofile = ""
  end

  def table_row
    [
      "JOB_ONLY/#{@jid}",
      @dtime,
      @dbobj,
      @dbprofile,
      '--',
      '--'
    ]
  end

  def self.table_headers
    [
      'Job', 
      'Date',
      'DB Obj Cnt',
      'DB Profile',
      'DOI',
      'ARK'
    ]
  end

  def self.table_types
    [
      'qjob',
      '',
      'jobnote',
      '',
      'ajaxdoi',
      'ajaxark'
    ]
  end

  def dtime
    @dtime
  end

  def jid
    @jid
  end

  def setRecentItem(recentjob)
    @dbobj = recentjob.dbobj
    @dbprofile = recentjob.profile
  end
end

class JobList < MerrittJson
  def initialize(body)
    super()
    @jobs = []
    @jobHash = {}
    data = JSON.parse(body)
    data = fetchHashVal(data, 'fil:batchFileState')
    data = fetchHashVal(data, 'fil:jobFile')
    list = fetchArrayVal(data, 'fil:batchFile')
    list.each do |obj|
      j = Job.new(
        obj.fetch('fil:file', ''),
        obj.fetch('fil:fileDate', '')
      )
      @jobs.append(j)
      @jobHash[j.jid] = j
    end
  end

  def to_table
    table = []
    @jobs.sort {
      # reverse sort on date
      |a,b| b.dtime <=> a.dtime
    }.each do |job|
      table.append(job.table_row)
    end
    table
  end

  def jobs
    @jobs
  end

  def apply_recent_ingests(recentitems)
    recentitems.jobs.each do |jid, recentjob|
      if @jobHash.key?(jid)
        @jobHash[jid].setRecentItem(recentjob)
      end
    end
  end
end

class RecentSwordIngest < QueryObject
  def initialize(row)
      @bid = row[0].strip
      @jid = row[1].strip
      @profile = row[2].strip
      @submitted = row[3]
      @object_cnt = row[4]
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
  
  def submitted
      @submitted
  end

  def object_cnt
      @object_cnt
  end

  def dbobj
      "#{@bid}/#{@jid}; #{@object_cnt}"
  end
end

class RecentSwordIngests < MerrittQuery
  def initialize(config, days = 14)
      super(config)
      @jobs = {}
      run_query(
          %{
              select 
                  batch_id,
                  job_id, 
                  max(profile), 
                  max(submitted), 
                  count(*) 
              from 
                  inv_ingests 
              where 
                  submitted >= date_add(date(now()), INTERVAL -? DAY)
              and
                  batch_id = 'JOB_ONLY'
              group by 
                  batch_id,
                  job_id
              ;
          },
          [days]
      ).each do |r|
          ri = RecentSwordIngest.new(r)
          @jobs[ri.jid] = ri
      end
  end

  def jobs
      @jobs
  end
end