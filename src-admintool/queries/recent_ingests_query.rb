require 'time'
class RecentIngestsQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @day = get_param('day', Time.new.strftime('%Y-%m-%d'))
  end

  def get_title
    "Ingests for Day #{@day}"
  end

  def get_sql
    %{
      select 
        profile, 
        batch_id, 
        max(submitted), 
        count(*) 
      from 
        inv.inv_ingests 
      where 
        date(submitted) = ?
      group by 
        profile, 
        batch_id
      order by 
        max(submitted) desc
      ;
    }
  end

  def get_alternative_queries
    [
      {
        label: 'Prior Day', 
        url: 'path=recent_ingests&day=' + (Time.parse(@day) - 24*60*60).strftime('%Y-%m-%d')
      },
      {
        label: 'Next Day', 
        url: 'path=recent_ingests&day=' + (Time.parse(@day) + 24*60*60).strftime('%Y-%m-%d')
      }
    ]
  end

  def get_params
    [@day]
  end

  def get_headers(results)
    ['Ingest Profile', 'Batch Id', 'Submitted', 'Object Count']
  end

  def get_types(results)
    ['', 'batch', '', 'dataint']
  end

end
