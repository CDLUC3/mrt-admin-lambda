# frozen_string_literal: true

require_relative 'action'
require 'yaml'

# Collection Admin Task class - see config/actions.yml for description
class OpenSearchDescribeAction < AdminAction
  def initialize(config, action, path, myparams)
    super(config, action, path, myparams)
    file = 'import/filebeat/fields.json'
    @title = "Merritt OpenSearch Fields (#{File.ctime(file).to_s[0..15]})"
    @fields = JSON.parse(File.read(file))
    #load_registry
  end

  def load_registry
    reg = YAML.safe_load(File.read('import/filebeat/opensearch.registry.yml'), aliases: true)
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
    ['Field Name', 'Type', 'Statis']
  end

  def table_types
    ['name', '', 'status']
  end

  def perform_action
    convert_json_to_table({}.to_json)
  end

  def table_rows(_body)
    rows = []
    @fields.each do |val|
      name = val.fetch('name', '')
      next if name =~ /\.keyword$/
      type = val.fetch('type', '')
      rows.append([name, type, 'PASS'])
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
