class RecentIngestsQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
  end

  def get_title
    "Recent Ingests - Last Day"
  end

  def get_sql
    %{
      select 
        profile, 
        batch_id, 
        job_id, 
        max(submitted), 
        count(*) 
      from 
        inv.inv_ingests 
      where 
        submitted >= date_add(now(), Interval - 1 day)
      group by 
        profile, 
        batch_id,
        job_id 
      order by 
        max(submitted) desc;
    }
  end

  def get_params
    []
  end

  def get_headers(results)
    ['Ingest Profile', 'Batch Id', 'Job Id', 'Submitted', 'Object Count']
  end

  def get_types(results)
    ['', 'batch', '', '', 'dataint']
  end

end
