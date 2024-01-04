# frozen_string_literal: true

require 'date'
require 'csv'

# individual property of a merritt json record
class MerrittJsonProperty
  # Define property
  # Optionally set the value
  def initialize(label, val = '')
    @label = label
    @value = val
  end

  def lookup_value(source, namespace, jsonkey, defval = nil)
    defval = @value if defval.nil?
    jsonkey = "#{namespace}:#{jsonkey}" unless namespace.empty?
    @value = source.fetch(jsonkey, defval)
    if defval.instance_of?(Array)
      @value = [@value] unless @value.instance_of?(Array)
    elsif defval.instance_of?(Hash)
      @value = {} if @value == ''
    end
    self
  end

  def lookup_time_value(source, namespace, jsonkey, defval = nil)
    lookup_value(source, namespace, jsonkey, defval)
    begin
      @value = DateTime.parse(@value).to_time
    rescue StandardError
      puts 'Time format error'
      @value = Time.new
    end
    self
  end

  attr_reader :value, :label
end

# wrapper around a merritt json object
class MerrittJson
  def self.template_key
    'TEMPLATE-PROFILE'
  end

  def initialize
    @property_list = []
    @property_hash = {}
  end

  def add_property(symbol, p)
    @property_list.append(symbol)
    @property_hash[symbol] = p
  end

  def set_property(symbol, p)
    @property_hash[symbol] = p
  end

  def get_value(symbol, defval = '')
    return defval unless @property_hash.key?(symbol)

    @property_hash[symbol].value
  end

  def get_time_value(symbol, defval = '')
    return defval unless @property_hash.key?(symbol)

    @property_hash[symbol].value
  end

  def get_label(symbol)
    return 'N/A' unless @property_hash.key?(symbol)

    @property_hash[symbol].label
  end

  def get_property_list
    @property_list
  end

  # Handle issues with Merritt Core2 JSON calls
  # Address issue in which single values are not returned as a single value array
  def self.json_fetch_array_val(obj, key)
    val = obj.fetch(key, [])
    val = [val] unless val.instance_of?(Array)
    val
  end

  def fetch_array_val(obj, key)
    MerrittJson.json_fetch_array_val(obj, key)
  end

  # Handle issues with Merritt Core2 JSON calls
  # Address issue in which an empty object is returned as an empty string
  def self.json_fetch_hash_val(obj, key)
    val = obj.fetch(key, {})
    # Ingest currently returns "" when empty
    val = {} if val == ''
    val
  end

  def fetch_hash_val(obj, key)
    MerrittJson.json_fetch_hash_val(obj, key)
  end
end
