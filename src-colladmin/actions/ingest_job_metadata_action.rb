# frozen_string_literal: true

require_relative 'action'
require_relative 'forward_to_ingest_action'

# Collection Admin Task class - see config/actions.yml for description
class IngestJobMetadataAction < ForwardToIngestAction
  def initialize(config, action, path, myparams)
    @batch = myparams.fetch('batch', '')
    @job = myparams.fetch('job', '')
    super(config, action, path, myparams, "admin/jid-erc/#{@batch}/#{@job}")
  end

  def get_title
    "Ingest Job #{@job}"
  end

  def table_rows(body)
    jm = JobMetadata.new(body)
    jm.to_table
  end

  def table_headers
    JobMetadataRecord.table_headers
  end

  def table_types
    JobMetadataRecord.table_types
  end

  def hasTable
    true
  end

  def get_alternative_queries
    [
      {
        label: 'Job Manifest',
        url: "#{LambdaBase.colladmin_url}?path=manifest&batch=#{@batch}&job=#{@job}",
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

# job metadata record
class JobMetadataRecord < MerrittJson
  def initialize(key, value)
    super()
    @key = key
    @value = value
  end

  def to_table_row
    [
      @key,
      @value
    ]
  end

  def self.table_headers
    %w[
      Key
      Value
    ]
  end

  def self.table_types
    [
      '',
      ''
    ]
  end
end

# ingest job metadata
class JobMetadata < MerrittJson
  def initialize(body)
    super()
    @metadata = []
    data = JSON.parse(body)
    data = data.fetch('fil:jobFileState', {})
    data = data.fetch('fil:jobFile', {})
    data.each_key do |k|
      @metadata.append(JobMetadataRecord.new(k, data.fetch(k, '')))
    end
  end

  def to_table
    rows = []
    @metadata.each do |jmr|
      rows.append(jmr.to_table_row)
    end
    rows
  end
end
