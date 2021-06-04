class ConsistencyReplicationReqQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
  end

  def report_name
    "#{@path}"
  end

  def get_title
    "Replication Required"
  end

  def get_sql
    %{
      select
      count(distinct p.inv_object_id) as obj,
      (
        select 
          sum(os.billable_size)
        from 
          object_size os
        where
          os.inv_object_id = p.inv_object_id
      ) as fbytes,
      ifnull(
        sum(
          case
            when o.created < date_add(now(), INTERVAL -2 DAY)
              then 1
            else 0
          end
        ),
        0
      ),
      ifnull(
        sum(
          case
            when o.created < date_add(now(), INTERVAL -2 DAY)
              then 0
            when o.created < date_add(now(), INTERVAL -1 DAY) 
              then 1
            else 0
          end
        ),
        0
      ),
      ifnull(
        sum(
          case
            when o.created < date_add(now(), INTERVAL -2 DAY)
              then 0
            when o.created < date_add(now(), INTERVAL -1 DAY) 
              then 0
            else 1
          end
        ),
        0
      ),   
      case
        when count(distinct p.inv_object_id) = 0 then 'PASS'
        when count(o.created < date_add(now(), INTERVAL -2 DAY)) > 0 then 'FAIL'
        when count(o.created < date_add(now(), INTERVAL -1 DAY)) > 0 then 'WARN'
       else 'PASS'
      end as status
    #{sqlfrag_replic_needed}
      ;
    }
  end

  def get_headers(results)
    ['Object Count', 'Byte Count', '> 2 days', '1-2 days', '< 1 day', 'Status']
  end

  def get_types(results)
    ['dataint', 'bytes', 'dataint', 'dataint', 'dataint', 'status']
  end

  def bytes_unit
    "1000000000"
  end
  
  def init_status
    :PASS
  end

  def get_alternative_queries
    [
      {
        label: "Object List - Replication Needed, Older than 2 days", 
        url: "path=replication_needed&days=2&limit=500"
      }
    ]
  end

end
