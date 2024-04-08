# frozen_string_literal: true

require_relative 'action'
require_relative 'forward_to_ingest_action'

# Collection Admin Task class - see config/actions.yml for description
class IngestJobManifestAction < ForwardToIngestAction
  def initialize(config, action, path, myparams)
    @batch = myparams.fetch('batch', '')
    @job = myparams.fetch('job', '')
    super(config, action, path, myparams, "admin/jid-manifest/#{@batch}/#{@job}")
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

  def has_table
    true
  end

  def get_alternative_queries
    [
      {
        label: 'Job Metadata',
        url: "#{LambdaBase.colladmin_url}?path=job&batch=#{@batch}&job=#{@job}",
        class: 'jobmeta'
      },
      {
        label: 'Job Files',
        url: "#{LambdaBase.colladmin_url}?path=files&batch=#{@batch}&job=#{@job}",
        class: 'jobmeta'
      }
    ]
  end
end

# ingest manifest entry
class JobManifestEntry < MerrittJson
  @@placeholder = nil
  def self.placeholder
    @@placeholder = JobManifestEntry.new({}) if @@placeholder.nil?
    @@placeholder
  end

  def initialize(json)
    super()
    add_property(
      :fileSize,
      MerrittJsonProperty.new('File Size').lookup_value(json, 'ingmans', 'fileSize')
    )
    add_property(
      :mimeType,
      MerrittJsonProperty.new('Mime Type').lookup_value(json, 'ingmans', 'mimeType')
    )
    add_property(
      :fileName,
      MerrittJsonProperty.new('File Name').lookup_value(json, 'ingmans', 'fileName')
    )
    add_property(
      :hashValue,
      MerrittJsonProperty.new('Hash Value').lookup_value(json, 'ingmans', 'hashValue')
    )
    add_property(
      :hashAlgorithm,
      MerrittJsonProperty.new('Hash Algorithm').lookup_value(json, 'ingmans', 'hashAlgorithm')
    )
  end

  def self.table_headers
    JobManifestEntry.placeholder.get_property_list.map do |sym|
      JobManifestEntry.placeholder.get_label(sym)
    end
  end

  def self.table_types
    arr = []
    JobManifestEntry.placeholder.get_property_list.each do |sym|
      type = ''
      type = 'bytes' if sym == :fileSize
      arr.append(type)
    end
    arr
  end

  def to_table_row
    arr = []
    JobManifestEntry.placeholder.get_property_list.each do |sym|
      v = get_value(sym)
      arr.append(v)
    end
    arr
  end
end

# ingest manifest
class JobManifest < MerrittJson
  def initialize(body)
    super()
    @entries = []
    data = JSON.parse(body)
    data = fetch_hash_val(data, 'ingmans:manifestsState')
    data = fetch_hash_val(data, 'ingmans:manifests')
    list = fetch_array_val(data, 'ingmans:manifestEntryState')
    list.each do |obj|
      @entries.append(JobManifestEntry.new(obj))
    end
  end

  def to_table
    table = []
    @entries.each_with_index do |jme, i|
      break if i >= 5000

      table.append(jme.to_table_row)
    end
    table
  end
end
