class BigIngestQuery < AdminQuery
  def get_title
    "Big Ingests - Last Week"
  end

  def get_sql
    %{
      select 
        profile, 
        batch_id, 
        date(submitted), 
        count(*) 
      from 
        inv.inv_ingests 
      where 
        batch_id != 'JOB_ONLY'
      and 
        submitted >= date_add(now(), Interval -7 day)
      group by 
        profile, 
        batch_id, 
        date(submitted) 
      having 
        count(*) > 200
      order by 
        date(submitted) desc;
    }
  end

  def get_headers(results)
    ['Ingest Profile', 'Batch Id', 'Submitted', 'Object Count']
  end

  def get_types(results)
    ['', '', '', 'dataint']
  end

end
