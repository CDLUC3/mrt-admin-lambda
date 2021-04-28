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
        count(a.id) as pcount,
        ifnull(
          sum(
            case 
              when a.inv_node_id in (select id from inv.inv_nodes where access_mode != 'on-line') 
                then 0
              else full_size
            end
          ), 
          0
        ) as online_bytes,
      from
        inv.inv_audits a
      inner join inv.inv_files f
        on 
          f.id = a.inv_file_id
        and 
          f.inv_object_id = a.inv_object_id
        and
          f.inv_version_id = a.inv_version_id
      where
        verified >= ?
      and
        verified < ?
      ;
    }
  end

  def get_headers(results)
    ['Time Frame', 'Files Processed', 'Bytes Processed']
  end

  def get_types(results)
    ['', 'dataint', 'bytes']
  end

  def bytes_unit
    "1000000000"
  end

end
