# frozen_string_literal: true

require 'date'
require 'csv'

class MerrittJsonProperty
  # Define property
  # Optionally set the value
  def initialize(label, val = '')
    @label = label
    @value = val
  end

  def lookupValue(source, namespace, jsonkey, defval = nil)
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

  def lookupTimeValue(source, namespace, jsonkey, defval = nil)
    lookupValue(source, namespace, jsonkey, defval)
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

class MerrittJson
  def self.TEMPLATE_KEY
    'TEMPLATE-PROFILE'
  end

  def initialize
    @propertyList = []
    @propertyHash = {}
  end

  def addProperty(symbol, p)
    @propertyList.append(symbol)
    @propertyHash[symbol] = p
  end

  def setProperty(symbol, p)
    @propertyHash[symbol] = p
  end

  def getValue(symbol, defval = '')
    return defval unless @propertyHash.key?(symbol)

    @propertyHash[symbol].value
  end

  def getTimeValue(symbol, defval = '')
    return defval unless @propertyHash.key?(symbol)

    @propertyHash[symbol].value
  end

  def getLabel(symbol)
    return 'N/A' unless @propertyHash.key?(symbol)

    @propertyHash[symbol].label
  end

  def getPropertyList
    @propertyList
  end

  # Handle issues with Merritt Core2 JSON calls
  # Address issue in which single values are not returned as a single value array
  def self.jsonFetchArrayVal(obj, key)
    val = obj.fetch(key, [])
    val = [val] unless val.instance_of?(Array)
    val
  end

  def fetchArrayVal(obj, key)
    MerrittJson.jsonFetchArrayVal(obj, key)
  end

  # Handle issues with Merritt Core2 JSON calls
  # Address issue in which an empty object is returned as an empty string
  def self.jsonFetchHashVal(obj, key)
    val = obj.fetch(key, {})
    # Ingest currently returns "" when empty
    val = {} if val == ''
    val
  end

  def fetchHashVal(obj, key)
    MerrittJson.jsonFetchHashVal(obj, key)
  end
end
