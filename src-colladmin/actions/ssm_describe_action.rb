require_relative 'action'
require 'aws-sdk-ssm'
require 'yaml'

class SsmInfo
  def initialize(name, inst = nil)
    # do not dump or display value attributes
    @name = name
    arr = @name.split("/")
    @subservice = arr[4]
    @type = inst.nil? ? "" : inst.data_type
    @description = ""
    @modified = inst.nil? ? "" : inst.last_modified_date.to_s
    @skip = false
  end

  def status
    return "SKIP" if @skip
    return "FAIL" if @modified.empty?
    return "WARN" if @description.empty?
    "PASS"
  end

  def set_skip(skip)
    @skip = skip
  end

  def set_description(description)
    @description = description
  end

  def name
    @name
  end

  def self.table_headers
    [
      "Name",
      "Type",
      "Subservice",
      "Description",
      "Modified",
      "Status"
    ]
  end

  def self.table_types
    [
      "name",
      "",
      "",
      "name",
      "datetime",
      "status"
    ]
  end

  def table_row
    [
      @name,
      @type,
      @subservice,
      @description,
      @modified,
      status
    ]
  end
end

class SsmDescribeAction < AdminAction

  def initialize(config, path, myparams)
    super(config, path, myparams)
    region = ENV['AWS_REGION'] || 'us-west-2'
    @ssm = Aws::SSM::Client.new(
      region: region, 
    )
    @title = "Merritt Parameters"
    @parameters = {}
    first = true
    nexttoken = nil
    while(first || nexttoken)
      first = false
      params = {max_results: 10, path: LambdaBase.ssm_root_path, recursive: true}
      params[:next_token] = nexttoken unless nexttoken.nil?
      # do not dump or display value attributes
      data = @ssm.get_parameters_by_path(params)
      data.parameters.each do |p|
        # do not dump or display value attributes
        n = p.name
        next if n.empty?
        @parameters[n] = SsmInfo.new(n, p)
      end
      nexttoken = data.next_token
    end
    load_registry
  end

  def load_registry
    reg = YAML.load_file("config/ssm.registry.yml")
    process_registry_node(LambdaBase.ssm_root_path.chop, reg)
  end

  def process_registry_node(path, reg)
    skip = skip 
    if reg.key?("description")
      p = @parameters.fetch(path, SsmInfo.new(path))
      p.set_description(reg["description"])
      p.set_skip(reg.fetch("skip", false))
      @parameters[path] = p
      return
    end

    reg.keys.each do |k|
      r = reg[k]
      next unless r.class.to_s == "Hash"
      process_registry_node("#{path}/#{k}", r)
    end

    if reg.fetch("skip", false)
      @parameters.keys.each do |pp|
        next unless pp =~ %r[^#{path}.*]
        @parameters[pp].set_skip(true)
      end
    end
  end

  def get_title
    @title
  end

  def table_headers
    SsmInfo.table_headers
  end

  def table_types
    SsmInfo.table_types
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
    @parameters.keys.sort.each do |k|
      rows.append(@parameters[k].table_row)
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