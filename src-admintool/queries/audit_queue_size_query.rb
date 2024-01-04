# frozen_string_literal: true

# Query class - see config/reports.yml for description
class AuditQueueSizeQuery < AdminQuery
  def get_title
    'Audit Queue Size Query'
  end

  def get_sql
    %{
      select
        verified,
        count(a.id) as file_count,
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
        case
          when verified is null and min(f.created) < date_add(now(), INTERVAL -1 DAY) then 'FAIL'
          when verified is null and min(f.created) < date_add(now(), INTERVAL -10 HOUR) then 'WARN'
          when verified < date_add(now(), INTERVAL -1 DAY) then 'FAIL'
          when verified < date_add(now(), INTERVAL -10 HOUR) then 'WARN'
          else 'PASS'
        end as status
      from
        inv.inv_files f
      inner join inv.inv_audits a
        on
          f.id = a.inv_file_id
        and
          f.inv_object_id = a.inv_object_id
        and
          f.inv_version_id = a.inv_version_id
      where
        status='processing'
      group by
        verified
      ;
    }
  end

  def get_headers(_results)
    ['Batch Time', 'Count in Processing Queue', 'On-line bytes in processing Queue', 'Status']
  end

  def get_types(_results)
    ['', 'dataint', 'bytes', 'status']
  end

  def bytes_unit
    '1000000000'
  end

  def init_status
    :PASS
  end
end
