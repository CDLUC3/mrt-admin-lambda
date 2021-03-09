class MerrittJson
   
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