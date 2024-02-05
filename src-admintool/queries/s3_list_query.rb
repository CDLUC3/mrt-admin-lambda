# frozen_string_literal: true

require 'tempfile'

# Query class - see config/reports.yml for description
class S3ListQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    rptpath = myparams.fetch('rptpath', 'daily-build')
    @report = "merritt-reports/#{rptpath}"
  end

  def run_sql
    no_data
  end

  def get_alternative_queries
    res = []
    resp = @s3_client.list_objects_v2({
      bucket: @s3bucket,
      prefix: @report
    })
    # Delete any prior reports
    # consistency-reports is intentionally hard coded into the delete
    resp.contents.each do |s3obj|
      res.push(
        {
          label: s3obj.key,
          url: get_report_url(s3obj.key),
          class: 'download'
        }
      )
    end

    res
  end
end
