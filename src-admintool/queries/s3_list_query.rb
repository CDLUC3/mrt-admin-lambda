# frozen_string_literal: true

require 'tempfile'

# Query class - see config/reports.yml for description
class S3ListQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    rptpath = myparams.fetch('rptpath', 'daily-build')
    status_file = myparams.fetch('status-file', '')
    @report = "merritt-reports/#{rptpath}"
    @files = []
    @status = 'SKIP'

    begin
      unless status_file.empty?
        resp = @s3_client.get_object({
          bucket: @s3bucket,
          key: "#{@report}/#{status_file}"
        })
        @status = resp.body.read.chop
      end
    rescue StandardError
      LambdaBase.log_config(config, "#{@report}/#{status_file} does not exist")
    end

    resp = @s3_client.list_objects_v2({
      bucket: @s3bucket,
      prefix: @report
    })
    resp.contents.each do |s3obj|
      link = "#{s3obj.key};#{get_report_url(s3obj.key)}"
      @files.push([link, s3obj.last_modified, s3obj.size, @status])
    end
  end

  def get_headers
    %w[File Modified Size Status]
  end

  def get_types
    %w[link datetime bytes status]
  end

  def run_sql
    return_data(@files, get_types, get_headers)
  end

  def init_status
    :PASS
  end
end
