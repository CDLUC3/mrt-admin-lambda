require 'cgi'
# require 'aws-sdk-s3'
require 'zip'
require 'mysql2'
require 'aws-sdk-s3'
require 'time'

class AdminAction
  def initialize(config, path, myparams)
    @config = config
    @s3bucket = ""
    @s3consistency = ""
    @path = path
    @myparams = myparams
    @format = 'report'
    @merritt_path = config.fetch('merritt_path','na')
    @report_status = init_status
  end

  def hasTable
    false
  end

  def convertJsonToTable(body)
    return body unless hasTable
    evaluate_status(table_types, table_rows(body))
    {
      format: 'report',
      title: get_title,
      headers: table_headers,
      types: table_types,
      data: table_rows(body),
      filter_col: nil,
      group_col: nil,
      show_grand_total: false,
      merritt_path: @merritt_path,
      alternative_queries: get_alternative_queries,
      iterate: false,
      bytes_unit: bytes_unit,
      saveable: is_saveable?,
      report_path: report_path
    }.to_json
  end

  def table_headers
    []
  end

  def table_types
    []
  end

  def table_rows(body)
    []
  end

  def get_param(key, defval)
    @myparams.key?(key) ? CGI.unescape(@myparams[key].strip) : defval
  end

  def get_title
    "Collection Admin Query"
  end

  def get_alternative_queries
    []
  end

  def bytes_unit
    "1"
  end

  def is_saveable?
    report_status != "SKIP" && !@s3bucket.empty?
  end

  def report_name
    @path
  end

  def init_status
    :SKIP
  end

  def evaluate_status(types, data)
    stat_col = -1
    types.each_with_index do |s, i|
      next unless s == 'status'
      stat_col = i
      break
    end
    return if @report_status == :SKIP
    return if @report_status == :FAIL
    data.each do |row|
      status = evaluate_row_status(row, stat_col)
      next if status == :PASS
      @report_status = status
      return if @report_status == :FAIL
    end
  end

  def evaluate_row_status(row, stat_col)
    return :PASS if stat_col == -1
    v = row[stat_col]
    return :FAIL if v == "FAIL"
    return :WARN if v == "WARN"
    :PASS
  end

  def report_status
    return "FAIL" if @report_status == :FAIL
    return "WARN" if @report_status == :WARN
    return "PASS" if @report_status == :PASS
    return "SKIP" if @report_status == :SKIP
    "SKIP"
  end

  def report_date
    Time.new.strftime('%Y-%m-%d')
  end

  def report_path
    "#{@s3bucket}:#{@s3consistency}#{report_date}/#{report_name}.#{report_status}"
  end

  def save_report(path, report)
    return unless is_saveable?
    #@s3_client.put_object({
    #  body: report.to_json,
    #  bucket: @s3bucket,
    #  key: report_path
    #})
  end

end
