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
    @format = myparams.key?('format') ? myparams['format'] : 'report'
  end

  def get_param(key, defval)
    @myparams.key?(key) ? CGI.unescape(@myparams[key].strip) : defval
  end

  def get_title
    "Merritt Admin Query"
  end

  def get_filter_col
    nil
  end

  def get_group_col
    nil
  end

  def show_grand_total
    get_filter_col != nil || get_group_col != nil
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

  def get_iterative_sql
    ""
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

  def is_number? string
    true if Float(string) rescue false
  end
  
  def is_int? string
    true if Integer(string) rescue false
  end

  def format_result_json(types, data, headers)
    if @format == 'report'
      {
        format: 'report',
        title: get_title,
        headers: headers,
        types: types,
        data: data,
        filter_col: get_filter_col,
        group_col: get_group_col,
        show_grand_total: show_grand_total,
        merritt_path: @merritt_path,
        alternative_queries: get_alternative_queries,
        iterate: @iterate
      }
    else
      results = []
      data.each do |r|
        row = {}
        headers.each_with_index do |c, i|
          if types[i] != 'na'
            row[c]=r[i]
            if is_int?(row[c])
              row[c] = Integer(row[c])
            elsif is_number?(row[c])
              row[c] = Float(row[c])
            end
          end
        end
        results.push(row)
      end
      {
        data: results
      }
    end
  end

  def get_result_json(results)
    types = get_types(results)
    data = get_result_data(results, types)
    headers = get_headers(results)
    format_result_json(types, data, headers)
  end

  def get_alternative_queries
    #[{label: '', url: ''}]
    []
  end

  def verify_interval_unit(unit) 
    return unit if unit == 'DAY'
    return unit if unit == 'HOUR'
    return unit if unit == 'MINUTE'
    return unit if unit == 'SECOND'
    return unit if unit == 'WEEK'
    return unit if unit == 'MONTH'
    return unit if unit == 'YEAR'
    'DAY'
  end

end
