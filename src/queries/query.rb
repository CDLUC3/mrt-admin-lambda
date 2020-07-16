class AdminQuery
  def initialize(client, path, myparams)
    @client = client
    @path = path
    @myparams = myparams
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

  def get_sql
    "SELECT 'hello' as greeting, user() as user;"
  end

  def run_sql
    stmt = @client.prepare(get_sql)
    query_params = get_params
    results = stmt.execute(*query_params)
    get_result_json(results)
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
        type = types[c];
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
      filter_col: get_filter_col
    }
  end

end
