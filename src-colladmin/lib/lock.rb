class LockEntry < MerrittJson
  @@placeholder = nil
  def self.placeholder
    @@placeholder = LockEntry.new({}) if @@placeholder.nil?
    @@placeholder
  end

  def initialize(json)
    super()
    addProperty(
      :date, 
      MerrittJsonProperty.new("Lock Date").lookupTimeValue(json, "loc", "date")
    )
    addProperty(
      :job, 
      MerrittJsonProperty.new("Job").lookupValue(json, "loc", "jobID")
    )
    addProperty(
      :ark, 
      MerrittJsonProperty.new("Profile").lookupValue(json, "loc", "iD")
    )
  end

  def self.table_headers
    arr = []
    LockEntry.placeholder.getPropertyList.each do |sym|
      arr.append(QueueEntry.placeholder.getLabel(sym))
    end
    arr
  end

  def self.table_types
    arr = []
    LockEntry.placeholder.getPropertyList.each do |sym|
      type = ''
      type = 'qjob' if sym == :job
      type = 'datetime' if sym == :date
      arr.append(type)
    end
    arr
  end

  def to_table_row
    arr = []
    LockEntry.placeholder.getPropertyList.each do |sym|
      v = getValue(sym)
      arr.append(v)
    end
    arr
  end

  def jid
    getValue(:job)
  end

  def date
    getValue(:date)
  end

  def ark
    getValue(:ark)
  end
end

class LockList < MerrittJson
  def initialize(ingest_server, body)
    super()
    @ingest_server = ingest_server
    @body = body
    @locks = []
    data = JSON.parse(@body)
    data = fetchHashVal(data, 'loc:lockState')
    data = fetchHashVal(data, 'loc:lockEntries')
    fetchArrayVal(data, 'loc:lockEntryState').each do |qjson|
      @locks.append(LockEntry.new(qjson))
    end
  end

  def locks
    @locks
  end

  def to_table
    table = []
    @locks.each_with_index do |q, i|
      table.append(q.to_table_row)
    end
    table
  end

end
