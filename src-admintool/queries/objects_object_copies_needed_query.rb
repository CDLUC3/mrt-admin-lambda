class ObjectsObjectCopiesNeededQuery < ObjectsQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @copies = CGI.unescape(get_param('copies', '2')).to_i
    @days = CGI.unescape(get_param('days', '0')).to_i
    subsql = %{
      select
        distinct age.inv_object_id
      #{sqlfrag_object_copies(@copies, @days)}
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
    "Objects - Object Copies Needed - Older than #{@days} days (Limit #{get_limit})"
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
        label: "Objects - Object Copies Needed", 
        url: "path=object_copies_needed&days=0&limit=500"
      },
      {
        label: "Objects - Object Copies Needed, older than 1 day", 
        url: "path=object_copies_needed&days=1&limit=500"
      },
      {
        label: "Objects - Object Copies Needed, older than 2 days", 
        url: "path=object_copies_needed&days=2&limit=500"
      },
    ]
  end

end
