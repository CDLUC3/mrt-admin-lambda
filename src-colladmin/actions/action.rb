require_relative '../admin_task'
require 'cgi'
require 'zip'
require 'mysql2'

class AdminAction < AdminTask
  def initialize(config, action_def, path, myparams)
    super(config, path, myparams)
    @action_def = action_def
    @format = 'report'
  end

  def hasTable
    false
  end

  def convertJsonToTable(body)
    return body unless hasTable
    data = table_rows(body)
    data = paginate_data(data)
    evaluate_status(table_types, data)
    report = {
      format: 'report',
      title: get_title_with_pagination,
      headers: table_headers,
      types: table_types,
      data: data,
      filter_col: get_filter_col,
      group_col: get_group_col,
      show_grand_total: show_grand_total,
      merritt_path: @merritt_path,
      alternative_queries: get_alternative_queries_with_pagination,
      iterate: false,
      bytes_unit: bytes_unit,
      saveable: is_saveable?,
      report_path: report_path,
      description: get_description
    }
    save_report(report_path, report) if is_saveable?
    report.to_json
  end

  def get_description
    @action_def.fetch('description', '')
  end

  def table_headers
    []
  end

  def table_types
    []
  end

  def table_rows(body)
    []
  end

  def get_title
    "Collection Admin Query"
  end

  def get_this_query
    {
      label: "This Query",
      url: "#{LambdaBase.colladmin_url}?#{params_to_str(@myparams.clone)}"
    }
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

end
