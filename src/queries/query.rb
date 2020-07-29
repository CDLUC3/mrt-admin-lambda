require 'cgi'
class AdminQuery
  def initialize(query_factory, path, myparams)
    @client = query_factory.client
    @merritt_path = query_factory.merritt_path
    @path = path
    @myparams = myparams
    @iterate = myparams.key?('iterate')
    @itparam1 = get_param('itparam1', '')
    @itparam2 = get_param('itparam2', '')
    @itparam3 = get_param('itparam3', '')
  end

  def get_param(key, defval)
    @myparams.key?(key) ? CGI.unescape(@myparams[key].strip) : ''
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
    if @itparam1 != ''
      query_params.append(@itparam1)
    end
    if @itparam2 != ''
      query_params.append(@itparam2)
    end
    if @itparam3 != ''
      query_params.append(@itparam3)
    end
    query_params
  end

  def get_sql
    if @itparam2 != ''
      "SELECT 'hello' as greeting, user() as user, ? as param1, ? as param2;"
    elsif @itparam1 != ''
      "SELECT 'hello' as greeting, user() as user, ? as param;"
    else
      "SELECT 'hello' as greeting, user() as user;"
    end
  end

  def get_collection_query
    %{
      select
        0 as coll
      union
      select
        id as coll
      from
        inv.inv_collections
    }
  end

  def get_campus_query
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

  def get_campus_and_total_query
    %{
      select
        distinct ogroup,
        1 as seq
      from
        owner_collections
      union
      select
        distinct ogroup,
        2 as seq
      from
        owner_collections
      union
      select
        'ZZ' as ogroup,
        1 as seq
      order by
        ogroup,
        seq
    }
  end

  def get_iterative_sql
    get_campus_query
  end

  def is_total
    @itparam1 == 'ZZ'
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
