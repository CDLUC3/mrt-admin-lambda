# frozen_string_literal: true

require_relative 'action'
require_relative 'forward_to_ingest_action'

# Collection Admin Task class - see config/actions.yml for description
class IngestJobFilesAction < ForwardToIngestAction
  def initialize(config, action, path, myparams)
    @batch = myparams.fetch('batch', '')
    @job = myparams.fetch('job', '')
    super(config, action, path, myparams, "admin/jid-file/#{@batch}/#{@job}")
  end

  def get_title
    "Ingest Job Files #{@job}"
  end

  def table_headers
    JobFile.table_headers
  end

  def table_types
    JobFile.table_types
  end

  def table_rows(body)
    JobFiles.new(body).to_table
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
        label: 'Job Manifest',
        url: "#{LambdaBase.colladmin_url}?path=manifest&batch=#{@batch}&job=#{@job}",
        class: 'jobmeta'
      }
    ]
  end
end

# representation of a file in an ingest folder
class JobFile < MerrittJson
  def initialize(obj)
    super()
    @dtime = obj.fetch('fil:fileDate', '')
    @path = obj.fetch('fil:file', '')
  end

  def table_row
    [
      @dtime,
      @path
    ]
  end

  def self.table_headers
    %w[
      Date
      Path
    ]
  end

  def self.table_types
    [
      '',
      ''
    ]
  end

  attr_reader :dtime, :path
end

# representation of the files in an ingest folder
class JobFiles < MerrittJson
  def initialize(body)
    super()
    @entries = []
    data = JSON.parse(body)
    data = fetch_hash_val(data, 'fil:batchFileState')
    data = fetch_hash_val(data, 'fil:jobFile')
    list = fetch_array_val(data, 'fil:batchFile')
    list.each do |obj|
      @entries.append(JobFile.new(obj))
    end
  end

  def to_table
    table = []
    @entries.each_with_index do |jf, i|
      break if i >= 5000

      table.append(jf.table_row)
    end
    table
  end
end
