require_relative 'action'
require 'aws-sdk-ec2'
require 'aws-sdk-ssm'

class Ec2Info
  # See https://docs.aws.amazon.com/sdk-for-ruby/v2/api/Aws/EC2/Client.html#describe_instances-instance_method
  def initialize(config, inst)
    @config = config
    @state = inst.state.name
    @type = inst.instance_type
    @publicip = inst.public_ip_address
    @az = inst.placement.availability_zone
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
      "IP",
      "AZ",
      "Endpoint",
      "Notes"
    ]
  end

  def self.table_types
    [
      "",
      "",
      "",
      "",
      "",
      "",
      "endpoint",
      ""
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

  def notes(action)
    if @subservice == "access"
      srvr = action.get_ssm('store/zoo/AccessLarge')
      threshold = action.get_ssm('store/zoo/AccessQSize')
      return "" unless @name == srvr
      return "" if threshold.nil?
      threshold = threshold.to_i / 1000000
      return "Large Assembly Server, Threshold: #{threshold}M"
    end
    if @subservice == "ui"
      return "ui05 is a preview server" if LambdaBase.is_prod
    end
    ""
  end

  def table_row(action)
    [
      @name,
      @subservice,
      @type,
      @state,
      @publicip,
      @az,
      format_urls,
      notes(action)
    ]
  end
end

class TagAction < AdminAction

  def initialize(config, action, path, myparams)
    super(config, action, path, myparams)
    region = ENV['AWS_REGION'] || 'us-west-2'
    @ec2 = Aws::EC2::Client.new(
      region: region, 
    )
    @ssm = Aws::SSM::Client.new(
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

  def get_ssm(key)
    val = @ssm.get_parameter({name: "#{LambdaBase.ssm_root_path}#{key}"})[:parameter][:value]
    return val
  rescue StandardError => e
    ""
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

  def perform_action
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
      report_path: report_path,
      description: get_description
    }.to_json
  end

  def get_table_rows
    rows = []
    @instances.keys.sort.each do |k|
      rows.append(@instances[k].table_row(self))
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