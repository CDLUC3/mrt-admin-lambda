require 'date'
class MerrittJsonProperty
  # Define property
  # Optionally set the value
  def initialize(label, val = "")
    @label = label
    @value = val
  end

  def lookupValue(source, namespace, jsonkey, defval = nil)
    defval = @value if defval.nil?
    jsonkey = namespace.empty? ? jsonkey : "#{namespace}:#{jsonkey}"
    @value = source.fetch(jsonkey, defval)
    if defval.instance_of?(Array) 
      if !@value.instance_of?(Array)
        @value = [@value]
      end
    elsif defval.instance_of?(Hash)
      if @value == ""
        @value = {}
      end
    end
    self
  end

  def lookupTimeValue(source, namespace, jsonkey, defval = nil)
    lookupValue(source, namespace, jsonkey, defval)
    begin
      @value = DateTime.parse(@value).to_time
    rescue StandardError => e
      puts "Time format error"
    end
    self
  end

  def value
    @value
  end

  def label
    @label
  end
end

class MerrittJson
  def self.TEMPLATE_KEY
    "TEMPLATE-PROFILE"
  end

  def initialize
    @propertyList = []
    @propertyHash = {}
  end

  def addProperty(symbol, p)
    @propertyList.append(symbol)
    @propertyHash[symbol] = p
  end

  def getValue(symbol, defval = "")
    return defval unless @propertyHash.key?(symbol)
    @propertyHash[symbol].value
  end

  def getTimeValue(symbol, defval = "")
    return defval unless @propertyHash.key?(symbol)
    @propertyHash[symbol].value
  end

  def getLabel(symbol)
    return "N/A" unless @propertyHash.key?(symbol)
    @propertyHash[symbol].label
  end

  def getPropertyList
    @propertyList
  end

  # Handle issues with Merritt Core2 JSON calls
  # Address issue in which single values are not returned as a single value array
  def fetchArrayVal(obj, key)
    val = obj.fetch(key, [])
    val = [val] unless val.instance_of?(Array)
    val
  end

  # Handle issues with Merritt Core2 JSON calls
  # Address issue in which an empty object is returned as an empty string
  def fetchHashVal(obj, key)
    val = obj.fetch(key, {})
    # Ingest currently returns "" when empty
    val = {} if val == ""
    val
  end

end