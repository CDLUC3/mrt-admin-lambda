class ReportRetrieve < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @day = Time.new.strftime('%Y-%m-%d')
    @report = CGI.unescape(get_param('report', "#{@s3consistency}#{@day}"))
    m = @report.match(%r[#{@s3consistency}(\d\d\d\d-\d\d-\d\d)])
    @day = m[1] unless m.nil?
  end

  def get_title
    "Retrive Report #{@report}"
  end

  def run_sql
    json = get_report(@report)
    return json unless json.nil?
    super.run_sql
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
        url: "path=report&report=#{@s3consistency}#{(Time.parse(@day) - 24*60*60).strftime('%Y-%m-%d')}"
      },
      {
        label: 'Next Day', 
        url: "path=report&report=#{@s3consistency}#{(Time.parse(@day) + 24*60*60).strftime('%Y-%m-%d')}"
      }
    ]
  end

end
