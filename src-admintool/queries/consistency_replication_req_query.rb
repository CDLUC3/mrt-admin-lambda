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
        case
          when u.inv_object_id = (
            select id from inv.inv_objects where ark = 'ark:/99999/fk4t15qn1'
          ) 
            then 'Stage Exception'
          else 
            'Default'
        end as category,
        count(u.inv_object_id) as obj,
        sum(os.billable_size) as fbytes,
        ifnull(
          sum(
            case
              when u.modified < date_add(now(), INTERVAL -2 DAY)
                then 1
              else 0
            end
          ),
          0
        ) as day2,
        ifnull(
          sum(
            case
              when u.modified < date_add(now(), INTERVAL -2 DAY)
                then 0
              when u.modified < date_add(now(), INTERVAL -1 DAY) 
                then 1
              else 0
            end
          ),
          0
        ) as day1,
        ifnull(
          sum(
            case
              when u.modified < date_add(now(), INTERVAL -2 DAY)
                then 0
              when u.modified < date_add(now(), INTERVAL -1 DAY) 
                then 0
              else 1
            end
          ),
          0
        ) as day0,   
        case
          when count(distinct u.inv_object_id) = 0 then 'PASS'
          when 
            sum(
              case
                when u.modified < date_add(now(), INTERVAL -2 DAY)
                  then 1
                else 0
              end
            ) > 0 then 'FAIL'
          when 
            sum(
              case
                when u.modified < date_add(now(), INTERVAL -2 DAY)
                  then 0
                when u.modified < date_add(now(), INTERVAL -1 DAY) 
                  then 1
                else 0
              end
            ) > 0 then 'WARN'
         else 'PASS'
        end as status
      from (
        select 
          p.inv_object_id,
          o.created,
          o.modified
        #{sqlfrag_replic_needed}
      ) as u
      inner join object_size os
        on os.inv_object_id = u.inv_object_id
      group by 
        category
      ;
    }
  end

  def get_headers(results)
    ['Category', 'Object Count', 'Bytes* (All Versions)', '> 2 days', '1-2 days', '< 1 day', 'Status']
  end

  def get_types(results)
    ['', 'dataint', 'bytes', 'dataint', 'dataint', 'dataint', 'status']
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
        url: "path=replication_needed&days=2&limit=500",
        class: 'objects'
      }
    ]
  end

end
