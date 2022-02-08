class ReplicationInitiatedQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
  end

  def get_title
    "Replication Initiated"
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
        count(i2.created) as seccnt,
        min(i2.version_number) as secmin,
        max(i2.version_number) as secmax
      from 
        inv.inv_nodes_inv_objects inio 
      inner join 
        inv.inv_objects o
      on
        o.id = inio.inv_object_id
      left join 
        inv.inv_nodes_inv_objects i2
      on 
        inio.inv_object_id = i2.inv_object_id
      and
        i2.role = 'secondary'
      where 
        inio.replicated is not null 
      and 
        inio.replicated < '1971-01-01'
      group by
        category,
        inio.inv_object_id,
        o.ark,
        o.version_number,
        o.created,
        inio.replic_start,
        bytes
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

  def get_headers(results)
    ['Category', 'Object Id', 'Ark', 'Version', 'Obj Created', 'Replic Start', 'Bytes','Sec Count', 'Ver Min', 'Ver Max']
  end

  def get_types(results)
    ['name', 'objlist', 'ark', '', 'datetime', 'datetime', 'bytes','','','']
  end

end
