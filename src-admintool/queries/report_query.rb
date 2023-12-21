# frozen_string_literal: true

# Query class - see config/reports.yml for description
class ReportRetrieve < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @day = Time.new.strftime('%Y-%m-%d')
    @report = CGI.unescape(get_param('report', "#{@s3consistency}#{@day}"))
    @report_base = @report
      .sub(@s3consistency, '')
      .gsub(%r{(\d\d\d\d-\d\d-\d\d)/}, '')
      .gsub(/\.(PASS|INFO|WARN|FAIL|SKIP)$/, '')
    m = @report.match(/#{@s3consistency}(\d\d\d\d-\d\d-\d\d)/)
    @day = m[1] unless m.nil?
  end

  def get_title
    "Retrive Report: #{@report}"
  end

  def run_sql
    json = get_report(@report)
    json = super.run_sql if json.nil?
    unless @report_base =~ /\d\d\d\d-\d\d-\d\d/
      prior_day = (Time.parse(@day) - (24 * 60 * 60)).strftime('%Y-%m-%d')
      next_day = (Time.parse(@day) + (24 * 60 * 60)).strftime('%Y-%m-%d')
      json.fetch('alternative_queries', json.fetch(:alternative_queries, []))
        .append(
          {
            label: "Prior Day - #{@report_base}",
            url: "path=report&report=#{@s3consistency}#{prior_day}/#{@report_base}",
            class: 'report'
          },
          {
            label: "Next Day - #{@report_base}",
            url: "path=report&report=#{@s3consistency}#{next_day}/#{@report_base}",
            class: 'report'
          }
        )
    end
    json
  end

  def is_saveable?
    false
  end

  def init_status
    :PASS
  end

  def get_alternative_queries
    [
      {
        label: 'Prior Day',
        url: "path=report&report=#{@s3consistency}#{(Time.parse(@day) - (24 * 60 * 60)).strftime('%Y-%m-%d')}",
        class: 'report'
      },
      {
        label: 'Next Day',
        url: "path=report&report=#{@s3consistency}#{(Time.parse(@day) + (24 * 60 * 60)).strftime('%Y-%m-%d')}",
        class: 'report'
      }
    ]
  end
end
