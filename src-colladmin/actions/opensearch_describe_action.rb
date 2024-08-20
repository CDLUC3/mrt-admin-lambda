# frozen_string_literal: true

require_relative 'action'
require 'yaml'

# Collection Admin Task class - see config/actions.yml for description
class OpenSearchDescribeAction < AdminAction
  def initialize(config, action, path, myparams)
    super
    file = 'import/filebeat/fields.json'
    @title = "Merritt OpenSearch Fields (#{File.mtime(file).to_s[0..15]})"
    @fields = {}
    JSON.parse(File.read(file)).each do |val|
      name = val.fetch('name', '')
      next if name =~ /\.keyword$/

      type = val.fetch('type', '')
      @fields[name] = {
        name: name,
        type: type,
        status: 'PASS'
      }
    end
    @reg = load_registry
  end

  def load_registry
    YAML.safe_load_file('import/filebeat/opensearch.registry.yml', aliases: true)
  end

  def get_title
    @title
  end

  def table_headers
    ['Field Name', 'Type', 'Description', 'Note', 'Source', 'Status']
  end

  def table_types
    ['', '', '', '', '', 'status']
  end

  def perform_action
    convert_json_to_table({}.to_json)
  end

  def get_doc(freg, key, defval)
    v = freg.fetch(key, defval)
    # empty yaml is returned as nil
    v = defval if v.nil?
    v
  end

  def process_key(k, defstat)
    f = @fields.fetch(k, {})
    freg = @reg.fetch(k, {})
    stat = 'PASS'
    stat = defstat if f.empty? || freg.empty?
    desc = get_doc(freg, 'description', '')
    source = get_doc(freg, 'source', '')
    note = get_doc(freg, 'note', '')
    stat = 'INFO' if stat == 'PASS' && desc.empty?
    [
      k,
      f.fetch(:type, ''),
      desc,
      note,
      source,
      stat
    ]
  end

  def table_rows(_body)
    oskeys = {}

    @fields.each_key do |k|
      oskeys[k] = process_key(k, 'FAIL')
    end
    @reg.each_key do |k|
      next if oskeys.key?(k)

      oskeys[k] = process_key(k, 'WARN')
    end
    oskeys.keys.sort.map do |k|
      oskeys[k]
    end
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
