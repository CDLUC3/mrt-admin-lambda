# frozen_string_literal: true

require_relative 'action'
require 'aws-sdk-ssm'
require 'yaml'

# information about an ssm parameter
class SsmInfo
  def initialize(name, inst = nil)
    # do not dump or display value attributes
    @name = name
    arr = @name.split('/')
    @subservice = arr[4]
    @type = inst.nil? ? '' : inst.type
    @description = ''
    @value = inst.nil? ? '' : inst.value
    @encrypted = @type == 'SecureString'
    if @encrypted == false &&
      (name !~ (%r{ldap/accounts/guest/password})) &&
      (name =~ /password|credential|privateAccess|accessKey|secretKey|master_key/)
      @encrypted = 'TBD'
    end
    @encrypted = '' if @value.empty?
    @keyid = ''
    @deprecated = ''
    @modified = inst.nil? ? '' : inst.last_modified_date.to_s
    @skip = false
  end

  def status
    return 'SKIP' if @skip
    return 'FAIL' if @modified.empty?
    return 'WARN' if @description.empty?
    return 'INFO' unless @deprecated.empty?

    'PASS'
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

  attr_reader :name, :deprecated, :skip
  attr_accessor :keyid

  def value
    return '' if @value.nil? || @value.empty?
    return '***' unless @encrypted == false

    @value
  end

  def self.table_headers
    %w[
      Name
      Type
      Subservice
      Description
      Encrypted
      Key
      Value
      Deprecated
      Modified
      Status
    ]
  end

  def self.table_types
    [
      'name',
      'narrow',
      'narrow',
      'name',
      'narrow',
      'narrow',
      'name',
      '',
      'datetime',
      'status'
    ]
  end

  def table_row
    [
      @name,
      @type,
      @subservice,
      @description,
      @encrypted,
      @keyid,
      value,
      @deprecated,
      @modified,
      status
    ]
  end
end

# Collection Admin Task class - see config/actions.yml for description
class SsmDescribeAction < AdminAction
  def initialize(config, action, path, myparams)
    super
    region = ENV['AWS_REGION'] || 'us-west-2'
    @ssm = Aws::SSM::Client.new(
      region: region
    )
    @title = 'Merritt Parameters'
    @parameters = {}
    first = true
    nexttoken = nil
    while first || nexttoken
      first = false
      params = { max_results: 10, path: LambdaBase.ssm_root_path, recursive: true }
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
    begin
      first = true
      nexttoken = nil
      while first || nexttoken
        first = false
        params = { filters: [{ key: 'Type', values: ['SecureString'] }] }
        params[:next_token] = nexttoken unless nexttoken.nil?
        # do not dump or display value attributes
        data = @ssm.describe_parameters(params)
        data.parameters.each do |p|
          # do not dump or display value attributes
          n = p.name
          next unless parameters.key?(n)

          @parameters[n].keyid = p.key_id
        end
        nexttoken = data.next_token
      end
    rescue StandardError
      # skip if permissions are not available
    end
    load_registry
  end

  def load_registry
    reg = YAML.safe_load_file('config/ssm.registry.yml', aliases: true)
    process_registry_node(LambdaBase.ssm_root_path.chop, reg)
  end

  def process_registry_node(path, reg)
    if reg.key?('description')
      p = @parameters.fetch(path, SsmInfo.new(path))
      p.set_description(reg['description'])
      p.set_deprecated(reg.fetch('deprecated', ''))
      p.set_skip(reg.fetch('skip', false))
      @parameters[path] = p
      return
    end

    reg.each_key do |k|
      r = reg[k]
      next unless r.instance_of?(::Hash)

      process_registry_node("#{path}/#{k}", r)
    end

    return unless reg.fetch('skip', false)

    @parameters.each_key do |pp|
      next unless pp =~ /^#{path}.*/

      @parameters[pp].set_skip(true)
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
    convert_json_to_table({}.to_json)
  end

  def table_rows(_body)
    rows = []
    @parameters.keys.sort.each do |k|
      next if @parameters[k].skip && @parameters[k].value.empty?

      rows.append(@parameters[k].table_row)
    end
    rows
  end

  def has_table
    true
  end

  def get_alternative_queries
    []
  end

  def init_status
    :PASS
  end
end
