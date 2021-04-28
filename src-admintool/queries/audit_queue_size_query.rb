class AuditQueueSizeQuery < AdminQuery
  def get_title
    "Audit Queue Size Query"
  end

  def get_sql
    %{
      select
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
        count(a.id) as file_count 
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
      and
        verified > date_add(now(), INTERVAL -1 DAY)
      ;
    }
  end

  def get_headers(results)
    ['Size of Processing Queue', 'Count in Processing Queue']
  end

  def get_types(results)
    ['bytes', 'dataint']
  end

  def bytes_unit
    "1000000000"
  end

end
