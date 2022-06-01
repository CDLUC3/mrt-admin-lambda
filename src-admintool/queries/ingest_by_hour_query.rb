class IngestBytesByHourQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
  end

  def get_title
    "Ingest by Hour Query"
  end

  def get_sql
    sql = %{
      select
        date_format(times.ts, 'D%Y-%m-%d_%H') as timeblock, 
        ifnull(sum(billable_size), 0) as bytes 
      from 
        (
    } 
    for h in 0..42
      sql = sql + %{ union } unless h == 0
      sql = sql + %{
          select date_add(date(now()), interval (((hour(now()) div 4) * 4) - (#{h} * 4)) hour) as ts
      }
    end
    sql = sql + %{
        ) times
      left join inv.inv_files f
        on times.ts = date_add(date(f.created), interval ((hour(f.created) div 4) * 4) hour) 
        and f.created > date_add(now(), interval -7 day)
      group by timeblock
      ; 
    }
    sql
  end

  def get_headers(results)
    ['Hour', 'Bytes']
  end

  # do not use the "bytes" type for import into excel
  def get_types(results)
    ['', 'dataint']
  end
  
  def bytes_unit
    "1000000000"
  end
  
  def is_line_chart
    true
  end
end
