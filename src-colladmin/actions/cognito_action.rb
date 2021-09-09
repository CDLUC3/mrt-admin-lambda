require_relative 'action'
require_relative '../lib/merritt_cognito'

class CognitoAction < AdminAction

  def initialize(config, path, myparams)
    super(config, path, myparams)
    @cognito = MerrittCognito.new(config)
    @title = "Cognito Users"
  end

  def get_title
    @title
  end

  def table_headers
    CognitoUser.get_headers
  end

  def table_types
    CognitoUser.get_types
  end

  def get_data
    evaluate_status(table_types, get_table_rows)
    {
      format: 'report',
      title: get_title_with_pagination,
      headers: table_headers,
      types: table_types,
      data: get_table_rows,
      filter_col: nil,
      group_col: nil,
      show_grand_total: false,
      merritt_path: @merritt_path,
      alternative_queries: get_alternative_queries_with_pagination,
      iterate: false,
      saveable: is_saveable?,
      report_path: report_path
    }.to_json
  end

  def get_table_rows
    rows = []
    @cognito.users.keys.sort.each do |k|
      rows.append(@users[k].table_row)
    end
    rows
  end

  def hasTable
    true
  end

  def get_alternative_queries
    []
  end

end