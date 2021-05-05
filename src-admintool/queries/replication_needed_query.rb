class ReplicationNeededQuery < ObjectsQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @days = CGI.unescape(get_param('days', '0')).to_i
    subsql = %{
      select
        p.inv_object_id
      from
        inv.inv_nodes_inv_objects p
      inner join
        inv.inv_objects o
      on 
        o.id = p.inv_object_id
      and
        o.created < date_add(now(), INTERVAL -#{@days} DAY)
      where
        p.role='primary'
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
      limit #{get_limit};
    }
    stmt = @client.prepare(subsql)
    results = stmt.execute()
    @ids = []
    @qs = []
    results.each do |r|
      @ids.push(r.values[0])
      @qs.push('?')
    end
  end

  def get_title
    "Objects - Replication Needed - Older than #{@days} days"
  end

  def get_params
    @ids
  end

  def get_where
    "where o.id in (#{@qs.join(',')})"
  end

  def get_max_limit
    500
  end

  def get_alternative_queries
    [
      {
        label: "Objects - Replication Required", 
        url: "path=replication_needed&days=0&limit=500"
      },
      {
        label: "Objects - Replication Required, older than 1 day", 
        url: "path=replication_needed&days=1&limit=500"
      },
      {
        label: "Objects - Replication Required, older than 2 days", 
        url: "path=replication_needed&days=2&limit=500"
      },
    ]
  end

end
