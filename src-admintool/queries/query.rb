require_relative '../admin_task'

class AdminQuery < AdminTask
  def initialize(query_factory, path, myparams)
    super(query_factory.config, path, myparams)
    @client = query_factory.client
    @limit = @myparams.fetch("limit", get_default_limit.to_s).to_i
    @limit = @limit > get_max_limit ? get_max_limit : @limit
    @iterate = myparams.key?('iterate')
    @itparam1 = get_param('itparam1', '')
    @itparam2 = get_param('itparam2', '')
    @itparam3 = get_param('itparam3', '')
    @format = myparams.key?('format') ? myparams['format'] : 'report'
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

  def show_iterative_total
    false
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

  def format_result_json(types, data, headers)
    if @format == 'report'
      evaluate_status(types, data)
      report = {
        format: 'report',
        title: get_title,
        headers: headers,
        types: types,
        data: data,
        filter_col: get_filter_col,
        group_col: get_group_col,
        show_grand_total: show_grand_total,
        show_iterative_total: show_iterative_total,
        merritt_path: @merritt_path,
        alternative_queries: get_alternative_queries,
        iterate: @iterate,
        bytes_unit: bytes_unit,
        saveable: is_saveable?,
        report_path: report_path
      }
      save_report(report_path, report) if is_saveable?
      report
    else
      data_table_to_json(data, headers)
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

  def get_limit
    @limit
  end

  def get_default_limit
    50
  end

  def get_max_limit
    500
  end

  def get_alternative_limit_queries
    queries = []
    limits = []
    [10, 20, 50, 100, 200, 500, 1000].each do |limit|
      limits.append(limit) if limit <= get_max_limit
    end
    limits.each do |limit|
      params = @myparams
      params['limit'] = limit
      queries.append({
        label: "Limit #{limit}", 
        url: params_to_str(params)
      })
    end
    queries
  end

  # Re-usable query fragments

  def sqlfrag_replic_needed
    %{
      from
      inv.inv_nodes_inv_objects p
    inner join
      inv.inv_objects o
    on 
      o.id = p.inv_object_id
    where
      p.role='primary'
    and
      not exists(
        select
          1
        from
          inv.inv_nodes_inv_objects s
        where
          s.role='secondary'
        and
          p.inv_object_id = s.inv_object_id
      )  
    }
  end

  def sqlfrag_audit_files_copies(copies)
    %{
      from (
        select 
          a.inv_object_id,
          a.inv_file_id,
          min(created) as init_created
        from
          inv.inv_audits a
        inner join (
          select 
            inv_file_id, 
            count(*) 
          from 
            inv.inv_audits 
          group by 
            inv_file_id 
          having 
            count(*) = #{copies}
        ) as copies
          on copies.inv_file_id = a.inv_file_id
        group by 
          inv_object_id,
          inv_file_id 
      ) as age
    }
  end

  def sqlfrag_object_copies(copies)
    %{
      from (
        select 
          inio.inv_object_id,
          min(created) as init_created
        from
          inv.inv_nodes_inv_objects inio
        inner join (
          select 
            inv_object_id, 
            count(*) 
          from 
            inv.inv_nodes_inv_objects 
          group by 
            inv_object_id 
          having 
            count(*) = #{copies}
        ) as copies
          on copies.inv_object_id = inio.inv_object_id
        group by 
          inv_object_id 
      ) as age
    }
  end

end