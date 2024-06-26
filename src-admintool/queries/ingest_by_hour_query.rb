# frozen_string_literal: true

# Query class - see config/reports.yml for description
class IngestBytesByHourQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super
    defdays = 7
    defend = (Time.new + spd).strftime('%Y-%m-%d')
    defstart = (Time.new - (defdays * spd)).strftime('%Y-%m-%d')

    @tend = get_param('end', defend)
    @tend = defend unless Time.parse(@tend)

    if myparams.key?('start')
      @tstart = get_param('start', defstart)
      @tstart = defstart unless Time.parse(@tstart)
      @days = ((Time.parse(@tend) - Time.parse(@tstart)) / spd).to_i
      unless @days.positive? && @days <= 100
        @days = defdays
        @tstart = defstart
      end
    else
      @days = get_param('days', defdays).to_i
      @days = defdays unless @days.positive? && @days <= 100
      @tstart = (Time.parse(@tend) - (@days * spd)).strftime('%Y-%m-%d')
    end
    if @days <= 3
      @tinc = 1
    elsif @days <= 14
      @tinc = 4
    else
      @tinc = 24
    end
  end

  def get_title
    "Ingest by Hour/Day Query: #{@tstart} - #{@tend} (#{@tinc} h)"
  end

  def get_sql
    sql = %{
      select
        date_format(times.ts, '%Y-%m-%d %H:00') as timeblock,
        ifnull(sum(billable_size), 0) as bytes
      from
        (
    }
    (0..((@days * 24 / @tinc) - 1)).each do |h|
      sql += %( union ) unless h.zero?
      sql += %{
          select date_add(
            '#{@tstart}',
            interval (((hour(now()) div #{@tinc}) * #{@tinc}) + (#{h} * #{@tinc})) hour
          ) as ts
      }
    end
    sql + %{
        ) times
      left join inv.inv_files f
        on times.ts = date_add(date(f.created), interval ((hour(f.created) div #{@tinc}) * #{@tinc}) hour)
        and f.created >= '#{@tstart}'
        and f.created < '#{@tend}'
      group by timeblock
      order by timeblock
      ;
    }
  end

  def get_headers(_results)
    %w[Hour Bytes]
  end

  # do not use the "bytes" type for import into excel
  def get_types(_results)
    ['', 'bytes']
  end

  def bytes_unit
    '1000000000'
  end

  def is_line_chart
    true
  end

  def spd
    24 * 60 * 60
  end

  def last_month_end
    (Time.now - (Time.now.mday * spd)).strftime('%Y-%m-%d')
  end

  def this_month_start
    ((Time.now - (Time.now.mday * spd)) + spd).strftime('%Y-%m-%d')
  end

  def last_month_start
    t = Time.parse(last_month_end)
    ((t - (t.mday * spd)) + spd).strftime('%Y-%m-%d')
  end

  def show_grand_total
    true
  end

  def get_alternative_queries
    [
      {
        label: 'Last 3 days (hourly)',
        url: 'path=ingest_bytes_by_hour&days=3',
        class: 'graph'
      },
      {
        label: 'Last 14 days (4 hour)',
        url: 'path=ingest_bytes_by_hour&days=14',
        class: 'graph'
      },
      {
        label: 'Last 30 days (24 hours)',
        url: 'path=ingest_bytes_by_hour&days=30',
        class: 'graph'
      },
      {
        label: 'Month to date',
        url: "path=ingest_bytes_by_hour&start=#{this_month_start}",
        class: 'graph'
      },
      {
        label: 'Last Month',
        url: "path=ingest_bytes_by_hour&start=#{last_month_start}&end=#{this_month_start}",
        class: 'graph'
      }
    ]
  end
end
