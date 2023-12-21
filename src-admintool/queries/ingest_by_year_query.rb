# frozen_string_literal: true

class IngestBytesByYearQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @defyears = 10
    @tend = "#{Time.new.year + 1}-01-01"
    @tstart = "#{Time.new.year - @defyears}-01-01"
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
    (0..@defyears).each do |y|
      sql += %( union ) unless y.zero?
      sql += %{
          select date_add(date('#{@tstart}'), interval #{y} YEAR) as ts
      }
    end
    sql + %{
        ) times
      left join owner_coll_mime_use_details f
        on times.ts = date_add(date(f.date_added), interval - dayofyear(f.date_added) + 1 DAY)
        and f.date_added >= '#{@tstart}'
        and f.date_added < '#{@tend}'
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
