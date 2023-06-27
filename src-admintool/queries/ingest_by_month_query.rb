class IngestBytesByMonthQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    defyears = 10
    @tend = "#{Time.new.year + 1}-01-01"
    @tstart = "#{Time.new.year - 10}-01-01"
  end

  def get_title
    "Ingest by Month Query"
  end

  def get_sql
    sql = %{
      select
        date_format(times.ts, '%Y-%m-%d %H:00') as timeblock, 
        ifnull(sum(billable_size), 0) as bytes 
      from 
        (
    } 
    for y in 0..10
      sql = sql + %{ union } unless y == 0
      sql = sql + %{
          select date_add(date('#{@tstart}'), interval #{y} YEAR) as ts
      }
    end
    sql = sql + %{
        ) times
      left join owner_coll_mime_use_details f
        on times.ts = date_add(date(f.date_added), interval - dayofyear(f.date_added) + 1 DAY) 
        and f.date_added >= '#{@tstart}'
        and f.date_added < '#{@tend}'
      group by timeblock
      order by timeblock
      ; 
    }
    sql
  end

  def get_headers(results)
    ['Week', 'Bytes']
  end

  # do not use the "bytes" type for import into excel
  def get_types(results)
    ['', 'bytes']
  end
  
  def bytes_unit
    "1000000000000"
  end
  
  def is_line_chart
    true
  end

  def show_grand_total
    true
  end

  def get_alternative_queries
    [
    ]
  end
end
