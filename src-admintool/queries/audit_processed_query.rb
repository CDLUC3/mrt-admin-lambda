class AuditProcessedQuery < AdminQuery
  def get_title
    "Audit Files Processed"
  end

  def get_iterative_sql
    sql = %{
      select
        'Last Minute',
        date_add(now(), interval -1 minute),
        now()
      union
      select
        'Last 5 Minutes',
        date_add(now(), interval -5 minute),
        now()
      union
      select
        'Last Hour',
        date_add(now(), interval -1 hour),
        now()
    }

    for i in 0..23
      sql = sql + %{
        union
        select
          concat(
            date_format(date_add(now(), interval -#{i+1} hour), '%H:00:00'),
            ' - ',
            date_format(date_add(now(), interval -#{i} hour), '%H:00:00')
          ),
          date_format(date_add(now(), interval -#{i+1} hour), '%Y-%m-%d %H:00:00'),
          date_format(date_add(now(), interval -#{i} hour), '%Y-%m-%d %H:00:00')
      }
    end

    for i in 0..5
      sql = sql + %{
        union
        select
          date(date_add(now(), INTERVAL -#{i+1} DAY)),
          date(date_add(now(), INTERVAL -#{i+1} DAY)),
          date(date_add(now(), INTERVAL -#{i} DAY))
      }
    end
    sql
  end

  def get_sql
    %{
      select
        ? as title,
        (
          select
            count(*)
          from
            inv.inv_audits
          where
            verified >= ?
          and
            verified < ?
          and
            status = 'verified'
         ) as pcount
        ;
    }
  end

  def get_headers(results)
    ['Time Frame', 'Files Processed']
  end

  def get_types(results)
    ['', 'dataint']
  end

end
