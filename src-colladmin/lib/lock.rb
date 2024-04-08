# frozen_string_literal: true

# information about a merritt lock
class LockEntry < MerrittJson
  @@placeholder = nil
  def self.placeholder
    @@placeholder = LockEntry.new({}) if @@placeholder.nil?
    @@placeholder
  end

  def initialize(json)
    super()
    add_property(
      :date,
      MerrittJsonProperty.new('Lock Date').lookup_time_value(json, 'loc', 'date')
    )
    add_property(
      :job,
      MerrittJsonProperty.new('Job').lookup_value(json, 'loc', 'jobID')
    )
    add_property(
      :ark,
      MerrittJsonProperty.new('Ark').lookup_value(json, 'loc', 'iD')
    )
  end

  def self.table_headers
    LockEntry.placeholder.get_property_list.map do |sym|
      LockEntry.placeholder.get_label(sym)
    end
  end

  def self.table_types
    arr = []
    LockEntry.placeholder.get_property_list.each do |sym|
      type = ''
      type = 'datetime' if sym == :date
      arr.append(type)
    end
    arr
  end

  def to_table_row
    arr = []
    LockEntry.placeholder.get_property_list.each do |sym|
      v = get_value(sym)
      arr.append(v)
    end
    arr
  end

  def jid
    get_value(:job)
  end

  def date
    get_value(:date)
  end

  def ark
    get_value(:ark)
  end
end

# list of merritt locks
class LockList < MerrittJson
  def initialize(ingest_server, body)
    super()
    @ingest_server = ingest_server
    @body = body
    @locks = []
    data = JSON.parse(@body)
    data = fetch_hash_val(data, 'loc:lockState')
    data = fetch_hash_val(data, 'loc:lockEntries')
    fetch_array_val(data, 'loc:lockEntryState').each do |qjson|
      @locks.append(LockEntry.new(qjson))
    end
  end

  attr_reader :locks

  def to_table
    table = []
    @locks.each_with_index do |q, _i|
      table.append(q.to_table_row)
    end
    table
  end
end
