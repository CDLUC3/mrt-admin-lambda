class ObjectsManyFilesQuery < ObjectsQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    subsql = %{
      select
        inv_object_id
      from
        object_size os
      inner join 
        inv.inv_objects o
      on 
        os.inv_object_id = o.id
      order by
        file_count desc
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
    @sort = 'count'
  end

  def get_title
    "Objects with Most Files"
  end

  def get_params
    @ids
  end

  # @qs was generated from a database query, so it is sanitized
  def get_where
    "where o.id in (#{@qs.join(',')})"
  end

  def get_max_limit
    50
  end

  def page_size
    get_limit
  end

  def get_obj_limit_query
    ""
  end

  def bytes_unit
    "1000000000"
  end

end
