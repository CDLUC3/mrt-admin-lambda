class BigIngestQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @days = get_param('days', '14').to_i
    @days = 365 if (@days > 365)
    @items = get_param('items', '200').to_i
    @items = 50 if (@items < 50)
  end

  def get_title
    "Big Ingests (#{@items}+) - Last #{@days} days"
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
        submitted >= date_add(now(), Interval - ? day)
      group by 
        profile, 
        batch_id, 
        date(submitted) 
      having 
        count(*) > ?
      order by 
        date(submitted) desc;
    }
  end

  def get_params
    [@days, @items]
  end

  def get_headers(results)
    ['Ingest Profile', 'Batch Id', 'Submitted', 'Object Count']
  end

  def get_types(results)
    ['', 'batch', '', 'dataint']
  end

end
