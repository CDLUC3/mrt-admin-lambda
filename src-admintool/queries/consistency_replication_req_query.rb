class ConsistencyReplicationReqQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @days = CGI.unescape(get_param('days', '0')).to_i
  end

  def report_name
    "#{@path}.#{@days}days"
  end

  def get_title
    "Replication Required, older than #{@days} days"
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
      case
        when count(distinct p.inv_object_id) = 0 then 'PASS'
        when #{@days} = 0 then 'SKIP'
        when #{@days} = 1 then 'WARN'
        when #{@days} >= 2 then 'FAIL'
        else 'SKIP'
      end as status
    #{sqlfrag_replic_needed(@days)}
      ;
    }
  end

  def get_headers(results)
    ['Object Count', 'Byte Count', 'Status']
  end

  def get_types(results)
    ['dataint', 'bytes', 'status']
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
        label: "Object List - Replication Needed", 
        url: "path=replication_needed&days=#{@days}&limit=500"
      },
      {
        label: "Replication Required", 
        url: "path=con_replic&days=0"
      },
      {
        label: "Replication Required, older than 1 day", 
        url: "path=con_replic&days=1"
      },
      {
        label: "Replication Required, older than 2 days", 
        url: "path=con_replic&days=2"
      },
    ]
  end

end
