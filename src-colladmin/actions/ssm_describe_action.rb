require_relative 'action'
require 'aws-sdk-ssm'
require 'yaml'

class SsmInfo
  def initialize(name, inst = nil)
    # do not dump or display value attributes
    @name = name
    arr = @name.split("/")
    @subservice = arr[4]
    @type = inst.nil? ? "" : inst.type
    @description = ""
    @encrypted = @type == 'SecureString'
    @encrypted = 'TBD' if @encrypted == false and name =~ %r[password|credential|privateAccess|accessKey|secretKey|master_key]
    @value = inst.nil? ? "" : inst.value
    @deprecated = ""
    @modified = inst.nil? ? "" : inst.last_modified_date.to_s
    @skip = false
  end

  def status
    return "SKIP" if @skip
    return "FAIL" if @modified.empty?
    return "WARN" if @description.empty?
    return "INFO" unless @deprecated.empty?
    "PASS"
  end

  def set_skip(skip)
    @skip = skip
  end

  def set_description(description)
    @description = description
  end

  def set_deprecated(deprecated)
    @deprecated = deprecated
  end

  def name
    @name
  end

  def value
    return "***" unless @encrypted == false
    return "" if @value.nil?
    @value
  end

  def deprecated
    @deprecated
  end

  def skip
    @skip
  end

  def self.table_headers
    [
      "Name",
      "Type",
      "Subservice",
      "Description",
      "Encrypted",
      "Value",
      "Deprecated",
      "Modified",
      "Status"
    ]
  end

  def self.table_types
    [
      "name",
      "narrow",
      "narrow",
      "name",
      "narrow",
      "name",
      "",
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
      @encrypted,
      value,
      @deprecated,
      @modified,
      status
    ]
  end
end

class SsmDescribeAction < AdminAction

  def initialize(config, action, path, myparams)
    super(config, action, path, myparams)
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
    reg = YAML.safe_load(File.read("config/ssm.registry.yml"), aliases: true)
    process_registry_node(LambdaBase.ssm_root_path.chop, reg)
  end

  def process_registry_node(path, reg)
    if reg.key?("description")
      p = @parameters.fetch(path, SsmInfo.new(path))
      p.set_description(reg["description"])
      p.set_deprecated(reg.fetch("deprecated", ""))
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

  def perform_action
    convertJsonToTable({}.to_json)
  end

  def table_rows(body)
    rows = []
    @parameters.keys.sort.each do |k|
      next if @parameters[k].skip && @parameters[k].value.empty?
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

  def init_status
    :PASS
  end

end