class ReplicationFailedQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
  end

  def get_title
    "Replication Failed"
  end

  def get_sql
    %{
      select 
        case
          when o.ark = 'ark:/13030/m5q57br8' then 'Wasabi Issue 477'
          else 'Default'
        end as category,
        inio.inv_object_id,
        o.ark,
        o.version_number,
        o.created,
        inio.replic_start,
        ifnull(inio.replic_size,0) as bytes,
        inio.completion_status,
        (
          select 
            group_concat(n.number)
          from
            inv.inv_nodes n
          inner join 
            inv.inv_nodes_inv_objects i2
          on
            i2.inv_node_id = n.id
          where
            i2.role = 'secondary'
          and
            i2.inv_object_id = inio.inv_object_id
          and
            i2.completion_status = 'fail'
        ) as nodes,
        case
          when o.ark = 'ark:/13030/m5q57br8' then 'INFO'
          else 'FAIL' 
        end as status      
      from 
        inv.inv_nodes_inv_objects inio 
      inner join 
        inv.inv_objects o
      on
        o.id = inio.inv_object_id
      where 
        inio.replicated is not null 
      and 
        inio.replicated < '1971-01-01'
      and
        inio.role = 'primary'
      and
        inio.completion_status in ('partial', 'fail')
      order by
        replic_start desc
      ;
    }
  end

  def get_filter_col
    4
  end

  def get_group_col
    0
  end

  def bytes_unit
    "1000000000"
  end

  def init_status
    :PASS
  end

  def get_headers(results)
    ['Category', 'Object Id', 'Ark', 'Version', 'Obj Created', 'Replic Start', 'Bytes', 'Rep Status', 'Fail Nodes', 'Status']
  end

  def get_types(results)
    ['name', 'objlist', 'ark', '', 'datetime', 'datetime', 'bytes', '', '', 'status']
  end

end
