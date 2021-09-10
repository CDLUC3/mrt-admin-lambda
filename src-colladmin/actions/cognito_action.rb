require_relative 'action'
require 'aws-sdk-lambda'

class CognitoAction < AdminAction

  def initialize(config, path, myparams)
    super(config, path, myparams)
    region = ENV['AWS_REGION'] || 'us-west-2'
    @lambda = Aws::Lambda::Client.new(
      region: region, 
      http_read_timeout: 10
    )
    @arn = @config.fetch("cognito-users-arn", "NA")
    @groups = @config.fetch("cognito-groups-to-manage", "")
    @headers = [
      "Username",
      "email"
    ]
    @types = [
      "",
      ""
    ]
    @groups.split(",").each do |g|
      @headers.push(g)
      @types.push("cognito")
    end
    @title = "Cognito Users"
  end

  def get_title
    @title
  end

  def table_headers
    @headers
  end

  def table_types
    @types
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
    return [] if @arn == "NA"

    if @path == "cognito-add-user-to-group"
      resp = @lambda.invoke({
        function_name: @arn, 
        payload: {
          userpool: @config.fetch("user-pool", "NA"),
          path: "add-user-to-group",
          group: CGI.unescape(@myparams.fetch("group", "")),
          user: CGI.unescape(@myparams.fetch("user", ""))
        }.to_json 
      })
      throw resp.function_error if resp.status_code != 200
    elsif @path == "cognito-remove-user-from-group"
      resp = @lambda.invoke({
        function_name: @arn, 
        payload: {
          userpool: @config.fetch("user-pool", "NA"),
          path: "remove-user-from-group",
          group: CGI.unescape(@myparams.fetch("group", "")),
          user: CGI.unescape(@myparams.fetch("user", ""))
        }.to_json 
      })
      throw resp.function_error if resp.status_code != 200
    end

    return_users
  end

  def return_users
    params = {
      userpool: @config.fetch("user-pool", "NA"),
      path: "list-users",
      groups: @groups
    }
    resp = @lambda.invoke({
      function_name: @arn, 
      payload: params.to_json 
    })

    throw resp.function_error if resp.status_code != 200

    # payload is serialized json
    payload = JSON.parse(resp.payload.read) 
    rows = []
    body = payload.fetch("body", {})
    body.each do |k, user|
      u = user.fetch("username", "")
      row = [
        u,
        user.fetch("email", "")
      ]
      @groups.split(",").each do |g|
        row.push(user.fetch(g, false) ? "Y;#{u};#{g}" : "N;#{u};#{g}")
      end
      rows.append(row)
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