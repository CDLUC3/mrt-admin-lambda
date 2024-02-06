# frozen_string_literal: true

require 'tempfile'

# Query class - see config/reports.yml for description
class S3ListQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    rptpath = myparams.fetch('rptpath', 'daily-build')
    @report = "merritt-reports/#{rptpath}"
    @files = [] 
    resp = @s3_client.list_objects_v2({
      bucket: @s3bucket,
      prefix: @report
    })
    resp.contents.each do |s3obj|
      link = "#{s3obj.key};#{get_report_url(s3obj.key)}"
      @files.push([link, s3obj.last_modified, s3obj.size])
    end
  end

  def get_headers
    ['File', 'Modified', 'Size']
  end

  def get_types
    ['link', 'datetime', 'bytes']
  end

  def run_sql
    return_data(@files, get_types, get_headers)
  end

end
