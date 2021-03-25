class ObjectsManyFilesQuery < ObjectsQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    subsql = %{
      select
        f.inv_object_id
      from
        inv.inv_files f
      group by
        f.inv_object_id
      having
        count(f.id) > 1000
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
    "Objects with Many Files (need to paginate)"
  end

  def get_params
    @ids
  end

  def get_where
    "where o.id in (#{@qs.join(',')})"
  end

  def get_max_limit
    50
  end

end
