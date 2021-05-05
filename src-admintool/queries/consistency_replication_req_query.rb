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
        sum(os.billable_size) as fbytes
      from
        inv.inv_nodes_inv_objects p
      inner join object_size os
        on os.inv_object_id = p.inv_object_id
      where
        p.role='primary'
      and
        created < date_add(now(), INTERVAL -? DAY)
      and
        not exists(
          select
            1
          from
            inv.inv_nodes_inv_objects s
          where
            s.role='secondary'
          and
            p.inv_object_id = s.inv_object_id
        )
      ;
    }
  end

  def get_params
    [ 
      @days
    ]
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
