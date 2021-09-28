require_relative 'action'
require 'aws-sdk-ec2'

class TagAction < AdminAction

  def initialize(config, path, myparams)
    super(config, path, myparams)
    region = ENV['AWS_REGION'] || 'us-west-2'
    @ec2 = Aws::EC2::Client.new(
      region: region, 
    )
    @title = "Merritt EC2 Instances"
    @instances = []

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
        instance = {}
        @instances.append(instance)
        instance[:state] = inst.state.name
        instance[:type] = inst.instance_type
        inst.tags.each do |tag|
          instance[:name] = tag.value if tag.key == 'Name'
        end
      end
    end
  end

  def get_title
    @title
  end

  def table_headers
    [
      "Name",
      "Type",
      "State",
      "State Endpoint"
    ]
  end

  def table_types
    [
      "name",
      "",
      "",
      ""
    ]
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
    @instances.each do |inst|
      rows.append([
        inst[:name],
        inst[:type],
        inst[:state],
        ""
      ])
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