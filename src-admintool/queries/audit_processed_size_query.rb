class AuditProcessedSizeQuery < AdminQuery
  def get_title
    "Audit Files Processed With Bytes"
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

    for i in 0..3
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

    sql
  end

  def get_sql
    %{
      select
        ? as title,
        (
          select
            count(*),
            (
              select 
                sum(full_size) 
              from 
                inv.inv_files f 
              where 
                f.id = a.inv_file_id
            )
          from
            inv.inv_audits a
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
    ['Time Frame', 'Files Processed', 'Bytes Processed']
  end

  def get_types(results)
    ['', 'dataint', 'Bytes']
  end

end
