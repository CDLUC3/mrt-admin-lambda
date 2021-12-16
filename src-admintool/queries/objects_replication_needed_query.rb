class ReplicationNeededQuery < ObjectsQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @days = get_param('days', '0').to_i
    subsql = %{
      select
        distinct p.inv_object_id
      #{sqlfrag_replic_needed}
      and
        o.modified < date_add(now(), INTERVAL -#{@days.to_i} DAY)
      limit #{get_limit.to_i} offset #{get_offset.to_i};
    }
    stmt = @client.prepare(subsql)
    results = stmt.execute()
    @ids = [-1]
    @qs = ['?']
    results.each do |r|
      @ids.push(r.values[0])
      @qs.push('?')
    end
  end

  def get_title
    "Objects - Replication Needed - Older than #{@days} days (Limit #{get_limit.to_i})"
  end

  def get_params
    @ids
  end

  # @qs is generated from a database query, so it is sanitized
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

  def page_size
    get_limit
  end

  def get_obj_limit_query
    ""
  end
end
