require 'cgi'
require 'aws-sdk-s3'
require 'time'

class AdminTask
  def initialize(config, path, myparams)
    @config = config
    @s3_client = Aws::S3::Client.new(region: 'us-west-2')
    @merritt_path = config['merritt_path']
    @s3bucket = config['s3-bucket']
    @s3consistency = config['s3-consistency-reports']
    @path = path
    @myparams = myparams
    @format = myparams.key?('format') ? myparams['format'] : 'report'
    @report_status = init_status
  end

  def get_param(key, defval)
    @myparams.key?(key) ? CGI.unescape(@myparams[key].strip) : defval
  end

  def get_title
    "Merritt Admin Task"
  end

  def is_number? string
    true if Float(string) rescue false
  end
  
  def is_int? string
    true if Integer(string) rescue false
  end

  def bytes_unit
    "1"
  end

  def is_saveable?
    return false if @s3bucket.nil?
    return false if @s3bucket.empty?
    report_status != "SKIP" 
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
    "#{@s3consistency}#{report_date}/#{report_name}.#{report_status}"
  end

  def save_report(path, report)
    return unless is_saveable?
    @s3_client.put_object({
      body: report.to_json,
      bucket: @s3bucket,
      key: report_path
    })
  end

  def return_data(data, types, headers)
    evaluate_status(types, data)
    {
      format: 'report',
      title: get_title,
      headers: headers,
      types: types,
      data: data,
      filter_col: nil,
      group_col: nil,
      show_grand_total: false,
      merritt_path: @merritt_path,
      alternative_queries: get_alternative_queries,
      iterate: false,
      bytes_unit: bytes_unit,
      saveable: is_saveable?,
      report_path: report_path
    }
  end

  def no_data 
    return_data(
      [[
        "No data"
      ]],
      [''],
      ['Message']
    )
  end

  def report_list(path, contents) 
    data = []
    contents.each do |c|
      m = c.key.match(/\.(SKIP|PASS|FAIL|WARN)$/)
      stat = m.nil? ? "SKIP" : m[1]
      data.append([c.key, stat])
    end

    return_data(
      data, 
      ['report', 'status'],
      ['Report', 'Status']
    )
  end

  def get_report(path)
    return no_data unless path =~ /^#{@s3consistency}/
    resp = @s3_client.list_objects_v2({
      bucket: @s3bucket,
      prefix: path
    })

    return no_data if resp.contents.length == 0
    return report_list(path, resp.contents) if resp.contents.length > 1
    return report_list(path, resp.contents) if (resp.contents[0].key != path) 

    resp = @s3_client.get_object({
      bucket: @s3bucket,
      key: path
    })
    result = resp.body.read
    JSON.parse(result)
  end

  def data_table_to_json(data, headers) 
    results = []
    data.each do |r|
      row = {}
      headers.each_with_index do |c, i|
        if types[i] != 'na'
          row[c]=r[i]
          if is_int?(row[c])
            row[c] = Integer(row[c])
          elsif is_number?(row[c])
            row[c] = Float(row[c])
          end
        end
      end
      results.push(row)
    end
    {
      data: results
    }
  end

  def get_result_json(results)
    types = get_types(results)
    data = get_result_data(results, types)
    headers = get_headers(results)
    format_result_json(types, data, headers)
  end

  def get_alternative_queries
    #[{label: '', url: ''}]
    []
  end

  def verify_interval_unit(unit) 
    return unit if unit == 'DAY'
    return unit if unit == 'HOUR'
    return unit if unit == 'MINUTE'
    return unit if unit == 'SECOND'
    return unit if unit == 'WEEK'
    return unit if unit == 'MONTH'
    return unit if unit == 'YEAR'
    'DAY'
  end

  def params_to_str(params)
    pstr = ""
    params.each do |k,v|
      pstr = "#{pstr}&" unless pstr.empty? 
      v = CGI.unescape(v) if v.instance_of?(String)
      pstr = "#{pstr}#{k}=#{v}"
    end 
    pstr
  end

  def datestr_to_date(str)
    DateTime.parse(str.to_s).to_time
  end
end