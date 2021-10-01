require_relative 'action'
require 'aws-sdk-ec2'

class Ec2Info
  def initialize(config, inst)
    @config = config
    @state = inst.state.name
    @type = inst.instance_type
    inst.tags.each do |tag|
      @name = tag.value if tag.key == 'Name'
      @subservice = tag.value if tag.key == 'Subservice'
    end
  end

  def name
    @name
  end

  def self.table_headers
    [
      "Name",
      "Subservice",
      "Type",
      "State",
      "Endpoint"
    ]
  end

  def self.table_types
    [
      "",
      "",
      "",
      "",
      "endpoint"
    ]
  end

  def urls
    res = {}
    return res unless @state == "running"

    @config.fetch("endpoints", {}).fetch(@subservice, {}).each do |k,v|
      res[k] = "http://#{@name}.cdlib.org:#{v}"
    end
    res
  end

  def format_urls
    str = ""
    urls.each do |k,v|
      str = "#{str};;" unless str.empty?
      str = "#{str}#{k};#{@name};#{v}"
    end
    str
  end

  def table_row
    [
      @name,
      @subservice,
      @type,
      @state,
      format_urls
    ]
  end
end

class TagAction < AdminAction

  def initialize(config, path, myparams)
    super(config, path, myparams)
    region = ENV['AWS_REGION'] || 'us-west-2'
    @ec2 = Aws::EC2::Client.new(
      region: region, 
    )
    @title = "Merritt EC2 Instances"
    @instances = {}
    @name = myparams.fetch("name", "")
    @label = myparams.fetch("label", "")
    @list_servers = @name.empty?

    data = @ec2.describe_instances({
      filters: [
        {
          name: "tag:Program",
          values: [LambdaBase.tag_program]
        },
        {
          name: "tag:Service",
          values: [LambdaBase.tag_service]
        },
        {
          name: "tag:Environment",
          values: [LambdaBase.tag_environment]
        }
      ]
    })

    data.reservations.each do |res|
      res.instances.each do |inst|
        ec2 = Ec2Info.new(config, inst)
        @instances[ec2.name] = ec2
      end
    end
  end

  def get_title
    @title
  end

  def table_headers
    Ec2Info.table_headers
  end

  def table_types
    Ec2Info.table_types
  end

  def endpoint_call
    return unless @instances[@name]
    ec2 = @instances[@name]
    url = ec2.urls.fetch(@label, "")
    return "No Url found" if url.empty?
    cli = HTTPClient.new
    resp = cli.get(url)
    unless resp.status == 200
      { 
        message: "Status #{resp.status} for #{url}" 
      }.to_json
    end
    resp.body
  end

  def get_data
    return endpoint_call unless @list_servers
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
    @instances.keys.sort.each do |k|
      rows.append(@instances[k].table_row)
    end
    rows
  end

  def hasTable
    @list_servers
  end

  def get_alternative_queries
    []
  end

end