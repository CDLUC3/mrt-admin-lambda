class ObjectsByJobQuery < ObjectsQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @job = CGI.unescape(get_param('job', ''))
    @batch = CGI.unescape(get_param('batch', ''))
  end

  def get_title
    "Objects By Ingest Batch/Job: #{@batch}/#{@job}"
  end

  def get_params
    [@batch,@job]
  end

  def get_where
    'where exists (
      select 
        1 
      from 
        inv.inv_ingests i 
      where 
        i.inv_object_id = o.id 
      and 
        i.batch_id=?
      and 
        i.job_id=?
    )'
  end
end
