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
        o.modified,
        ifnull(sum(os.billable_size),0) as bytes,
        count(i2.created) as seccnt,
        min(i2.version_number) as secmin,
        max(i2.version_number) as secmax
      from 
        inv.inv_nodes_inv_objects inio 
      inner join 
        inv.inv_objects o
      on
        o.id = inio.inv_object_id
      inner join 
        object_size os
      on 
        os.inv_object_id = inio.inv_object_id
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
        o.modified
      ;
    }
  end

  def get_headers(results)
    ['Category', 'Object Id', 'Ark', 'Version', 'Obj Created', 'Obj Modifed', 'Bytes','Sec Count', 'Ver Min', 'Ver Max']
  end

  def get_types(results)
    ['', 'objlist', 'ark', 'dataint', 'datetime', 'datetime', 'bytes','dataint','dataint','dataint']
  end

end