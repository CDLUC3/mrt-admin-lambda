# frozen_string_literal: true

# Query class - see config/reports.yml for description
class IngestBytesByMonthQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @defyears = 10
    @totit = @defyears * 12 + 1
    @tend = ((Date.today - Date.today.day + 1) >> 1).strftime('%Y-%m-%d')
    @tstart = ((Date.today - Date.today.day + 1) << (12 * @defyears)).strftime('%Y-%m-%d')
  end

  def get_title
    'Ingest by Month Query'
  end

  def get_sql
    sql = %{
      select
        date_format(times.ts, '%Y-%m-%d %H:00') as timeblock,
        ifnull(sum(billable_size), 0) as bytes
      from
        (
    }
    @totit.times do |y|
      sql += %( union ) unless y.zero?
      sql += %{
          select date_add(date('#{@tstart}'), interval #{y} MONTH) as ts
      }
    end
    sql + %{
        ) times
      left join owner_coll_mime_use_details f
        on times.ts = date_add(date(f.date_added), interval - dayofmonth(f.date_added) + 1 DAY)
        and f.date_added >= '#{@tstart}'
        and f.date_added < '#{@tend}'
        and f.billable_size >= 0
      group by timeblock
      order by timeblock
      ;
    }
  end

  def get_headers(_results)
    %w[Week Bytes]
  end

  # do not use the "bytes" type for import into excel
  def get_types(_results)
    ['', 'bytes']
  end

  def bytes_unit
    '1000000000000'
  end

  def is_line_chart
    true
  end

  def show_grand_total
    true
  end

  def get_alternative_queries
    []
  end
end
