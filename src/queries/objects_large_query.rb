class ObjectsLargeQuery < ObjectsQuery
  def initialize(client, path, myparams)
    super(client, path, myparams)
    subsql = %{
      select
        f.inv_object_id
      from
        inv.inv_files f
      group by
        f.inv_object_id
      having
        sum(f.billable_size) > 1073741824
      limit 50;
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
    "50 Large Objects (need to paginate)"
  end

  def get_params
    @ids
  end

  def get_where
    "o.id in (#{@qs.join(',')})"
  end
end
