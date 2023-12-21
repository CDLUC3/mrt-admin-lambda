# frozen_string_literal: true

require 'date'
require_relative 'forward_to_ingest_action'

# Collection Admin Task class - see config/actions.yml for description
class IngestSwordJobsAction < ForwardToIngestAction
  def initialize(config, action, path, myparams)
    @days = myparams.fetch('days', '3').to_i
    @days = 21 if @days > 21
    super(config, action, path, myparams, "admin/bid/JOB_ONLY/#{@days}")
  end

  def get_title
    "Sword Jobs: Last #{@days} days; (Note: the ark/doi loading code needs a bug fix)"
  end

  def table_headers
    Job.table_headers
  end

  def table_types
    Job.table_types
  end

  def table_rows(body)
    jlist = JobList.new(body, @days)
    recent = RecentSwordIngests.new(@config, @days)
    jlist.apply_recent_ingests(recent)
    jlist.to_table
  end

  def hasTable
    true
  end

  def get_alternative_queries
    [
      {
        label: 'Sword Jobs Last 3 days',
        url: "#{LambdaBase.colladmin_url}?path=sword&days=3",
        class: 'jobs'
      },
      {
        label: 'Sword Jobs Last 7 days',
        url: "#{LambdaBase.colladmin_url}?path=sword&days=7",
        class: 'jobs'
      },
      {
        label: 'Sword Jobs Last 14 days',
        url: "#{LambdaBase.colladmin_url}?path=sword&days=14",
        class: 'jobs'
      },
      {
        label: 'Sword Jobs Last 21 days',
        url: "#{LambdaBase.colladmin_url}?path=sword&days=21",
        class: 'jobs'
      }
    ]
  end

  def page_size
    1000
  end
end

# merritt ingest job
class Job < MerrittJson
  def initialize(jid, dtime)
    super()
    @jid = jid.strip
    @dtime = dtime
    @dbobj = ''
    @dbprofile = ''
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

  attr_reader :dtime, :jid

  def to_date
    Date.parse(@dtime)
  end

  def setRecentItem(recentjob)
    @dbobj = recentjob.dbobj
    @dbprofile = recentjob.profile
  end
end

# list of merritt ingest jobs
class JobList < MerrittJson
  def initialize(body, days)
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
      # puts j.to_date
      # puts Date.today - days
      next if j.to_date < (Date.today - days)

      @jobs.append(j)
      @jobHash[j.jid] = j
    end
  end

  def to_table
    table = []
    @jobs.sort do |a, b|
      b.dtime <=> a.dtime
    end.each do |job|
      table.append(job.table_row)
    end
    table
  end

  attr_reader :jobs

  def apply_recent_ingests(recentitems)
    recentitems.jobs.each do |jid, recentjob|
      @jobHash[jid].setRecentItem(recentjob) if @jobHash.key?(jid)
    end
  end
end

# reperesents a recent sword ingest job - obsolete class
class RecentSwordIngest < QueryObject
  def initialize(row)
    @bid = row[0].strip
    @jid = row[1].strip
    @profile = row[2].strip
    @submitted = row[3]
    @object_cnt = row[4]
  end

  attr_reader :bid, :jid, :profile, :submitted, :object_cnt

  def dbobj
    "#{@bid}/#{@jid}; #{@object_cnt}"
  end
end

# list of resent sword ingests - obsolete class
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

  attr_reader :jobs
end
