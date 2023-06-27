class IngestBytesByWeekQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    defweeks = 52
    defend = (Time.new + spw).strftime('%Y-%m-%d')
    defstart = (Time.new - defweeks * spw).strftime('%Y-%m-%d')

    @tend = get_param('end', defend)
    @tend = defend unless Time.parse(@tend)

    if myparams.key?('start')
      @tstart = get_param('start', defstart)
      @tstart = defstart unless Time.parse(@tstart)
      @weeks = ((Time.parse(@tend) - Time.parse(@tstart)) / spw ).to_i
      unless @weeks > 0 && @weeks <= 100
        @weeks = defweeks
        @tstart = defstart
      end
    else
      @weeks = get_param('weeks', defweeks).to_i
      @weeks = defweeks unless @weeks > 0 && @weeks <= 100
      @tstart = (Time.parse(@tend) - @weeks * spw).strftime('%Y-%m-%d')
    end
  end

  def get_title
    "Ingest by Week Query: #{@tstart} - #{@tend}"
  end

  def get_sql
    sql = %{
      select
        date_format(times.ts, '%Y-%m-%d %H:00') as timeblock, 
        ifnull(sum(billable_size), 0) as bytes 
      from 
        (
    } 
    for w in 0..(@weeks - 1)
      sql = sql + %{ union } unless w == 0
      sql = sql + %{
          select date_add(date_add(date('#{@tstart}'), INTERVAL -dayofweek('#{@tstart}') DAY), interval #{w}*7 DAY) as ts
      }
    end
    sql = sql + %{
        ) times
      left join owner_coll_mime_use_details f
        on times.ts = date_add(date(f.date_added), interval - dayofweek(f.date_added) DAY) 
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

  def spd
    24 * 60 * 60
  end

  def spw
    7 * spd
  end

  def last_year_end
    (Time.now - Time.now.yday * spd).strftime('%Y-%m-%d')
  end

  def this_year_start
    ((Time.now - Time.now.yday * spd) + spd).strftime('%Y-%m-%d')
  end

  def last_year_start
    t = Time.parse(last_year_end)
    ((t - t.yday * spd) + spd).strftime('%Y-%m-%d')
  end

  def show_grand_total
    true
  end

  def get_alternative_queries
    [
      {
        label: "Last 52 weeks", 
        url: "path=ingest_bytes_by_week&weeks=52",
        class: 'graph'
      },
      {
        label: "Year to date", 
        url: "path=ingest_bytes_by_week&start=#{this_year_start}",
        class: 'graph'
      },
      {
        label: "Last Year", 
        url: "path=ingest_bytes_by_week&start=#{last_year_start}&end=#{this_year_start}",
        class: 'graph'
      },
    ]
  end
end
