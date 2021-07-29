require_relative 'action'
require_relative 'forward_to_ingest_action'

class IngestJobManifestAction < ForwardToIngestAction
  def initialize(config, path, myparams)
    @batch = myparams.fetch('batch', '')
    @job = myparams.fetch('job', '')
    super(config, path, myparams, "admin/jid-manifest/#{@batch}/#{@job}")
  end

  def get_title
    "Ingest Job Manifest #{@job}"
  end

  def table_headers
    JobManifestEntry.table_headers
  end

  def table_types
    JobManifestEntry.table_types
  end

  def table_rows(body)
    JobManifest.new(body).to_table
  end

  def hasTable
    true
  end

  def get_alternative_queries
    [
      {
        label: 'Job Metadata', 
        url: "#{LambdaBase.colladmin_url}?path=job&batch=#{@batch}&job=#{@job}"
      },
      {
        label: 'Job Files', 
        url: "#{LambdaBase.colladmin_url}?path=files&batch=#{@batch}&job=#{@job}"
      },
    ]
  end

end

class JobManifestEntry < MerrittJson
  @@placeholder = nil
  def self.placeholder
    @@placeholder = JobManifestEntry.new({}) if @@placeholder.nil?
    @@placeholder
  end

  def initialize(json)
    super()
    addProperty(
      :fileSize, 
      MerrittJsonProperty.new("File Size").lookupValue(json, "ingmans", "fileSize")
    )
    addProperty(
      :mimeType, 
      MerrittJsonProperty.new("Mime Type").lookupValue(json, "ingmans", "mimeType")
    )
    addProperty(
      :fileName, 
      MerrittJsonProperty.new("File Name").lookupValue(json, "ingmans", "fileName")
    )
    addProperty(
      :hashValue, 
      MerrittJsonProperty.new("Hash Value").lookupValue(json, "ingmans", "hashValue")
    )
    addProperty(
      :hashAlgorithm, 
      MerrittJsonProperty.new("Hash Algorithm").lookupValue(json, "ingmans", "hashAlgorithm")
    )
  end

  def self.table_headers
    arr = []
    JobManifestEntry.placeholder.getPropertyList.each do |sym|
      arr.append(JobManifestEntry.placeholder.getLabel(sym))
    end
    arr
  end

  def self.table_types
    arr = []
    JobManifestEntry.placeholder.getPropertyList.each do |sym|
      type = ''
      type = 'bytes' if sym == :fileSize
      arr.append(type)
    end
    arr
  end

  def to_table_row
    arr = []
    JobManifestEntry.placeholder.getPropertyList.each do |sym|
      v = getValue(sym)
      arr.append(v)
    end
    arr
  end
end


class JobManifest < MerrittJson
  def initialize(body)
    super()
    @entries = []
    data = JSON.parse(body)
    data = fetchHashVal(data, 'ingmans:manifestsState')
    data = fetchHashVal(data, 'ingmans:manifests')
    list = fetchArrayVal(data, 'ingmans:manifestEntryState')
    list.each do |obj|
      @entries.append(JobManifestEntry.new(obj))
    end
  end

  def to_table
    table = []
    @entries.each_with_index do |jme, i|
      break if (i >= 5000) 
      table.append(jme.to_table_row)
    end
    table
  end
end

