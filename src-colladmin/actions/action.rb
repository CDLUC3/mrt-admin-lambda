require_relative 'src-common-link/admin_task'
require 'cgi'
require 'zip'
require 'mysql2'

class AdminAction < AdminTask
  def initialize(config, path, myparams)
    super(config, path, myparams)
    @format = 'report'
  end

  def hasTable
    false
  end

  def convertJsonToTable(body)
    return body unless hasTable
    evaluate_status(table_types, table_rows(body))
    {
      format: 'report',
      title: get_title,
      headers: table_headers,
      types: table_types,
      data: table_rows(body),
      filter_col: nil,
      group_col: nil,
      show_grand_total: false,
      merritt_path: @merritt_path,
      alternative_queries: get_alternative_queries,
      iterate: false,
      bytes_unit: bytes_unit,
      saveable: is_saveable?,
      report_path: report_path
    }.to_json
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

end
