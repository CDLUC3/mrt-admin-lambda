# frozen_string_literal: true

require_relative '../admin_task'

# Admin Tool Query base class 
class AdminQuery < AdminTask
  def initialize(query_factory, path, myparams)
    super(query_factory.config, path, myparams)
    @report_def = query_factory.get_report_def(path)
    @client = query_factory.client
    @limit = @myparams.fetch('limit', get_default_limit.to_s).to_i
    @limit = [@limit, get_max_limit].min
    @iterate = myparams.key?('iterate')
    @itparam1 = get_param('itparam1', '')
    @itparam2 = get_param('itparam2', '')
    @itparam3 = get_param('itparam3', '')
    @format = myparams.key?('format') ? myparams['format'] : 'report'
  end

  def get_description
    @report_def.fetch('description', '')
  end

  def get_breadcrumb
    @report_def.fetch('breadcrumb', '')
  end

  def get_title
    'Merritt Admin Query'
  end

  def show_iterative_total
    false
  end

  def get_params
    []
  end

  def resolve_params
    query_params = get_params
    query_params.append(@itparam1) if @itparam1 != ''
    query_params.append(@itparam2) if @itparam2 != ''
    query_params.append(@itparam3) if @itparam3 != ''
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
    ''
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
  rescue StandardError => e
    log(e)
    log(get_sql)
  end

  def run_query_sql
    sql = get_sql
    stmt = @client.prepare(sql)
    query_params = resolve_params
    results = stmt.execute(*query_params)
    get_result_json(results)
  rescue StandardError => e
    log(e)
    log(get_sql)
  end

  def get_headers(results)
    results.fields
  end

  def get_types(results)
    types = []
    results.fields.each do
      types.push('')
    end
  end

  def get_result_data(results, _types)
    data = []
    results.each do |r|
      rdata = []
      r.values.each_with_index do |v, _c|
        # type = types[c];
        rdata.push(v)
      end
      data.push(rdata)
    end
    paginate_data(data)
  end

  def format_result_json(types, data, headers)
    if @format == 'report'
      evaluate_status(types, data)
      report = {
        format: 'report',
        title: get_title_with_pagination,
        breadcrumb: get_breadcrumb,
        headers: headers,
        types: types,
        data: data,
        filter_col: get_filter_col,
        group_col: get_group_col,
        show_grand_total: show_grand_total,
        show_iterative_total: show_iterative_total,
        merritt_path: @merritt_path,
        alternative_queries: get_alternative_queries_with_pagination,
        iterate: @iterate,
        bytes_unit: bytes_unit,
        saveable: is_saveable?,
        report_path: report_path,
        chart: get_chart(data, types, headers),
        description: get_description
      }
      save_report(report_path, report) if is_saveable?
      report
    else
      data_table_to_json(types, data, headers)
    end
  end

  def get_result_json(results)
    types = get_types(results)
    data = get_result_data(results, types)
    headers = get_headers(results)
    format_result_json(types, data, headers)
  end

  def get_alternative_queries
    # [{label: '', url: ''}]
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

  def verify_col_group(col)
    %w[inv_collection_id ogroup].include?(col) ? col : 'inv_collection_id'
  end

  def verify_aggregate_role(role)
    return role if role == 'MRT-none'
    return role if role == 'MRT-owner'
    return role if role == 'MRT-service-level-agreement'
    return role if role == 'MRT-collection'
    return 'n/a' if role == 'MRT-none'

    'Null_Value'
  end

  def verify_day(day)
    return day if day =~ /^\d\d\d\d-\d\d-\d\d$/

    Time.new.strftime('%Y-%m-%d')
  end

  def verify_mime_col(col)
    %w[mime_type mime_group].include?(col) ? col : 'mime_type'
  end

  def verify_files_col(col)
    %w[count_files billable_size].include?(col) ? col : 'count_files'
  end

  def get_limit
    @limit
  end

  def get_offset
    @page * page_size
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
      params = @myparams.clone
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
        and
          s.version_number = o.version_number
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
            count(*) = #{copies.to_i}
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
            count(*) = #{copies.to_i}
        ) as copies
          on copies.inv_object_id = inio.inv_object_id
        group by
          inv_object_id
      ) as age
    }
  end

  def sqlfrag_version_clobber
    %{
      select
        inv_object_id,
        number,
        count(*)
      from
        inv.inv_versions
      group by
        inv_object_id,
        number
      having
        count(*) > 1
    }
  end

  def sqlfrag_version_gap
    %{
      select
        inv_object_id
      from
        inv.inv_versions
      group by
        inv_object_id
      having
        count(distinct number) != max(number)
    }
  end

  # since limit/offset have already been applied, do not slice the resulting array
  def paginate_data(fulldata)
    @known_total = fulldata.length
    fulldata
  end
end
