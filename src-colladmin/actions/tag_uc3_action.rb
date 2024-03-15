# frozen_string_literal: true

require_relative 'action'
require 'aws-sdk-ec2'
require 'aws-sdk-ssm'

# represents information about an EC2 instance
class Ec2InfoUc3
  # See https://docs.aws.amazon.com/sdk-for-ruby/v2/api/Aws/EC2/Client.html#describe_instances-instance_method
  def initialize(config, inst)
    @config = config
    @state = inst.state.name
    @type = inst.instance_type
    @publicip = inst.public_ip_address
    @az = inst.placement.availability_zone
    inst.tags.each do |tag|
      @name = tag.value if tag.key == 'Name'
      @service = tag.value if tag.key == 'Service'
      @subservice = tag.value if tag.key == 'Subservice'
    end
  end

  attr_reader :name

  def self.table_headers
    [
      'Name',
      'Service',
      'Subservice',
      'Type',
      'SERVER State',
      'IP',
      'AZ'
    ]
  end

  def self.table_types
    [
      '',
      '',
      '',
      '',
      '',
      '',
      ''
    ]
  end

  def table_row(_action)
    [
      @name,
      @service,
      @subservice,
      @type,
      @state,
      @publicip,
      @az
    ]
  end
end

# Collection Admin Task class - see config/actions.yml for description
class TagUc3Action < AdminAction
  def initialize(config, action, path, myparams)
    super(config, action, path, myparams)
    region = ENV['AWS_REGION'] || 'us-west-2'
    @ec2 = Aws::EC2::Client.new(
      region: region
    )
    @ssm = Aws::SSM::Client.new(
      region: region
    )
    @title = 'Merritt EC2 Instances'
    @instances = {}
    @name = myparams.fetch('name', '')
    @label = myparams.fetch('label', '')
    @list_servers = @name.empty?

    data = @ec2.describe_instances({
      filters: [
        {
          name: 'tag:Program',
          values: [LambdaBase.tag_program]
        },
        {
          name: 'tag:Environment',
          values: [LambdaBase.tag_environment]
        }
      ]
    })

    data.reservations.each do |res|
      res.instances.each do |inst|
        ec2 = Ec2InfoUc3.new(config, inst)
        @instances[ec2.name] = ec2
      end
    end
  end

  def get_ssm(key)
    @ssm.get_parameter({ name: "#{LambdaBase.ssm_root_path}#{key}" })[:parameter][:value]
  rescue StandardError
    ''
  end

  def get_title
    @title
  end

  def table_headers
    Ec2InfoUc3.table_headers
  end

  def table_types
    Ec2InfoUc3.table_types
  end

  def endpoint_call
    return unless @instances[@name]

    ec2 = @instances[@name]
    url = ec2.urls.fetch(@label, '')
    return 'No Url found' if url.empty?

    cli = HTTPClient.new
    cli.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
    if @label == 'stop' || @label == 'start'
      puts "POST #{url}"
      resp = cli.post(url)
    else
      puts "GET #{url}"
      resp = cli.get(url, follow_redirect: true)
    end
    ret = resp.body
    return ret if @label == 'build-info'

    if resp.status == 200
      begin
        JSON.parse(resp.body)
      rescue StandardError
        ret = { body: resp.dump }.to_json
      end
    else
      ret = {
        message: "Status #{resp.status} for #{url}"
      }.to_json
    end
    ret
  end

  def perform_action
    return endpoint_call unless @list_servers

    evaluate_status(table_types, get_table_rows)
    {
      format: 'report',
      title: get_title_with_pagination,
      breadcrumb: get_breadcrumb,
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
      chart: nil,
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

  def has_table
    @list_servers
  end

  def get_alternative_queries
    []
  end
end
