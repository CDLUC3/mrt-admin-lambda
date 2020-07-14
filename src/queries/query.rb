class AdminQuery
  def initialize(client)
    @client = client
  end

  def get_params
    []
  end

  def get_sql
    "SELECT 'hello' as greeting, user() as user;"
  end

  def run_sql
    stmt = @client.prepare(get_sql)
    results = stmt.execute(*get_params)
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

  def get_result_data(results)
    data = []
    results.each do |r|
      data.push(r.values)
    end
    data
  end

  def get_result_json(results)
    {
      headers: get_headers(results),
      types: get_types(results),
      data: get_result_data(results)
    }
  end
end
