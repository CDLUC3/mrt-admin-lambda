class ConsistencyReplicationReqQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @days = CGI.unescape(get_param('days', '0')).to_i
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
      ) as fbytes
    #{sqlfrag_replic_needed(@days)}
      ;
    }
  end

  def get_headers(results)
    ['Object Count', 'Byte Count']
  end

  def get_types(results)
    ['dataint', 'bytes']
  end

  def bytes_unit
    "1000000000"
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