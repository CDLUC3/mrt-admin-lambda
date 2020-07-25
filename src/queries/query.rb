class AdminQuery
  def initialize(query_factory, path, myparams)
    @client = query_factory.client
    @merritt_path = query_factory.merritt_path
    @path = path
    @myparams = myparams
    @iterate = myparams.key?('iterate')
    @itparam = myparams.key?('itparam') ? myparams['itparam'] : []
  end

  def get_title
    "Merritt Admin Query"
  end

  def get_filter_col
    nil
  end

  def get_params
    []
  end

  def resolve_params
    query_params = get_params
    @itparam.each do |p|
      query_params.append(p)
    end
    query_params
  end

  def get_sql
    if @itparam.length > 0
      "SELECT 'hello' as greeting, user() as user, ? as param;"
    else
      "SELECT 'hello' as greeting, user() as user;"
    end
  end

  def get_iterative_sql
    %{
      select
        distinct ogroup
      from
        owner_collections
      union
      select
        'ZZ' as ogroup
      order by
        ogroup
    }
  end

  def is_total
    @itparam[0] == 'ZZ'
  end

  def run_sql
    if @iterate
      run_iterative_sql
    else
      run_query_sql
    end
  end

  def run_iterative_sql
    sql = get_iterative_sql
    stmt = @client.prepare(sql)
    query_params = []
    results = stmt.execute(*query_params)
    get_result_json(results)
  rescue => e
    puts(e)
    puts(get_sql)
  end

  def run_query_sql
    sql = get_sql
    stmt = @client.prepare(sql)
    query_params = resolve_params
    results = stmt.execute(*query_params)
    get_result_json(results)
  rescue => e
    puts(e)
    puts(get_sql)
  end

  def get_headers(results)
    results.fields
  end

  def get_types(results)
    types = []
    results.fields.each do
      types.push("")
    end
  end

  def get_result_data(results, types)
    data = []
    results.each do |r|
      rdata = []
      r.values.each_with_index do |v, c|
        # type = types[c];
        rdata.push(v)
      end
      data.push(rdata)
    end
    data
  end

  def get_result_json(results)
    types = get_types(results)
    {
      title: get_title,
      headers: get_headers(results),
      types: types,
      data: get_result_data(results, types),
      filter_col: get_filter_col,
      merritt_path: @merritt_path,
      iterate: @iterate
    }
  end

end
