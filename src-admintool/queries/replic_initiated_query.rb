class ReplicationInitiatedQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)

    sql = %{
      select 
        count(*) 
      from 
        inv.inv_nodes_inv_objects 
      where 
        ifnull(replicated,'1970-01-01') < '1971-01-01' 
      and role='primary'
      ;
    }
    stmt = @client.prepare(sql)
    results = stmt.execute()

    @waiting = 0
    results.each do |r|
      @waiting = r.values[0]
    end
  end

  def get_title
    "Replication Initiated -- #{@waiting} Objects Waiting to Replicate"
  end

  def get_sql
    %{
      select 
        case
          when o.ark in ('ark:/13030/m5v45qp2', 'ark:/13030/j2br86wx', 'ark:/13030/j21n79mc') then 'Issue 951 - Admin Object'
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
        max(i2.version_number) as secmax,
        case
          when inio.replic_start is null and o.modified > date_add(now(), INTERVAL -4 HOUR)
            then 'PASS'
          when inio.replic_start is null 
            then 'INFO'
          when inio.replic_start > date_add(now(), INTERVAL -4 HOUR) 
            then 'PASS'
          when inio.replic_start > date_add(now(), INTERVAL -24 HOUR) 
            then 'WARN'
          else 'FAIL' 
        end as status      
    from 
        inv.inv_nodes_inv_objects inio 
      inner join 
        inv.inv_objects o
      on
        o.id = inio.inv_object_id
      inner join 
        inv.inv_nodes_inv_objects i2
      on 
        inio.inv_object_id = i2.inv_object_id
      and
        i2.role = 'secondary'
      where 
        inio.replic_start is not null 
      and 
        ifnull(inio.replicated, '1970-01-01') < '1971-01-01'
      and
        inio.role = 'primary'
      and
        ifnull(inio.completion_status, 'unknown') = 'unknown'
      group by
        category,
        inio.inv_object_id,
        o.ark,
        o.version_number,
        o.created,
        inio.replic_start,
        bytes,
        status
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
    ['Category', 'Object Id', 'Ark', 'Version', 'Obj Created', 'Replic Start', 'Bytes','Sec Count', 'Ver Min', 'Ver Max', 'Status']
  end

  def get_types(results)
    ['name', 'objlist', 'ark', '', 'datetime', 'datetime', 'bytes','','','', 'status']
  end

end
