class AuditQueueSizeQuery < AdminQuery
  def get_title
    "Audit Queue Size Query"
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
        ) as online_bytes
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

  def get_headers(results)
    ['Batch Time', 'Count in Processing Queue', 'On-line bytes in processing Queue']
  end

  def get_types(results)
    ['', 'dataint', 'bytes']
  end

  def bytes_unit
    "1000000000"
  end

end
