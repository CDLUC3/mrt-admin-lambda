class ObjectsFileCopiesNeededQuery < ObjectsQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @copies = CGI.unescape(get_param('copies', '2')).to_i
    @days = CGI.unescape(get_param('days', '2')).to_i
    subsql = %{
      select
        distinct age.inv_object_id
      #{sqlfrag_audit_files_copies(@copies)}
      where
        age.init_created < date_add(now(), INTERVAL -#{@days} DAY)
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
    "Objects with #{@copies} Copies - Older than #{@days} days (Limit #{get_limit})"
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
        label: "Objects with #{@copies} Copies", 
        url: "path=file_copies_needed&copies=#{@copies}&days=0&limit=500"
      },
      {
        label: "Objects with #{@copies} Copies, older than 1 day", 
        url: "path=file_copies_needed&copies=#{@copies}&days=1&limit=500"
      },
      {
        label: "Objects with #{@copies} Copies, older than 2 days", 
        url: "path=file_copies_needed&copies=#{@copies}&days=2&limit=500"
      },
    ]
  end

end
