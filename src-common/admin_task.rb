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
    @format = myparams.fetch('format', 'report')
    @page = myparams.fetch('page', '0').to_i
    @report_status = init_status
    @known_total = nil
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
    return if data.nil?
    data.each do |row|
      next if row.nil?
      status = evaluate_row_status(row, stat_col)
      next if status == :PASS
      next if status == :INFO && @report_status == :WARN
      @report_status = status
      return if @report_status == :FAIL
    end
  end

  def evaluate_row_status(row, stat_col)
    return :PASS if stat_col == -1
    v = row[stat_col]
    return :FAIL if v == "FAIL"
    return :WARN if v == "WARN"
    return :INFO if v == "INFO"
    :PASS
  end

  def report_status
    return "FAIL" if @report_status == :FAIL
    return "WARN" if @report_status == :WARN
    return "PASS" if @report_status == :PASS
    return "SKIP" if @report_status == :SKIP
    return "INFO" if @report_status == :INFO
    "SKIP"
  end

  def self.status_sort_val(val)
    return 0 if val == "FAIL"
    return 1 if val == "WARN"
    return 2 if val == "INFO"
    return 3 if val == "PASS"
    return 4 if val == "SKIP"
  end

  def report_date
    Time.new.strftime('%Y-%m-%d')
  end

  def report_path
    "#{@s3consistency}#{report_date}/#{report_name}.#{report_status}"
  end

  def report_path_prefix
    "#{@s3consistency}#{report_date}/#{report_name}."
  end

  def save_report(path, report)
    return unless is_saveable?
    # Look for any prior reports for the day
    resp = @s3_client.list_objects_v2({
      bucket: @s3bucket,
      prefix: report_path_prefix
    })
    # Delete any prior reports
    # consistency-reports is intentionally hard coded into the delete
    resp.contents.each do |s3obj|
      k = s3obj.key
      next unless k =~ %r[consistency-reports.*(SKIP|PASS|INFO|WARN|FAIL)$]
      r = @s3_client.delete_object({
        bucket: @s3bucket,
        key: k
      })
    end
    # Save a new object
    @s3_client.put_object({
      body: report.to_json,
      bucket: @s3bucket,
      key: report_path
    })
  end

  def save_data_report(path, data)
    @s3_client.put_object({
      body: data,
      bucket: @s3bucket,
      key: path
    })
  end

  def paginate_data(fulldata)
    @known_total = fulldata.length
    return fulldata if page_size == 0 || fulldata.length <= page_size
    ss = @page * page_size
    send = page_size 
    res = fulldata.slice(ss, send)
    res = [] if res.nil?
    res
  end

  def pagination
    return nil unless page_size > 0
    res = {
      current_page: @page,
      page_size: page_size
    }
    res[:prior_page] = @page - 1 if @page > 0
    if !@known_total.nil?
      res[:known_total] = @known_total
      res[:next_page] = @page + 1 if @known_total >= page_size
    end
    res
  end

  def page_size
    0
  end

  def return_data(data, types, headers)
    evaluate_status(types, data)
    {
      format: 'report',
      title: get_title_with_pagination,
      headers: headers,
      types: types,
      data: data,
      filter_col: nil,
      group_col: nil,
      show_grand_total: false,
      merritt_path: @merritt_path,
      alternative_queries: get_alternative_queries_with_pagination,
      iterate: false,
      bytes_unit: bytes_unit,
      saveable: is_saveable?,
      report_path: report_path,
      chart: get_chart(data, types, headers)
    }
  end

  def no_data 
    return_data(
      [[
        "No data",
        "WARN"
      ]],
      ['','status'],
      ['Message','Status']
    )
  end

  def message_as_table(msg) 
    return_data(
      [[
        msg
      ]],
      [''],
      ['Message']
    )
  end

  def report_list(path, contents) 
    data = []
    contents.each do |c|
      m = c.key.match(/\.(SKIP|PASS|INFO|WARN|FAIL)$/)
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

  def get_data_report(path)
    begin
      resp = @s3_client.get_object({
        bucket: @s3bucket,
        key: path
      })
      result = resp.body
    rescue
      ""
    end
  end

  def data_table_to_json(types, data, headers) 
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

  def get_filter_col
    nil
  end

  def get_group_col
    nil
  end

  def show_grand_total
    get_filter_col != nil || get_group_col != nil
  end

  def is_line_chart
    false
  end

  def is_pie_chart
    false
  end

  def has_chart
    is_line_chart || is_pie_chart
  end

  def get_label_col
    return get_group_col if get_group_col
    0
  end

  def get_data_col
    1
  end

  def get_chart_map(data)
    m = {}
    data.each do |r|
      m[r[get_label_col]] = m.fetch(r[get_label_col], 0) + r[get_data_col]
    end
    m
  end

  def get_line_chart(data, types, headers)
    m = get_chart_map(data)

    {
      type: 'line',
      data: {
        labels: m.keys,
        datasets: [{
          label: get_title,
          data: m.values,
        }]
      },
      options: {}
    };

  end

  def get_pie_chart(data, types, headers)
    m = get_chart_map(data)

    {
      type: 'pie',
      data: {
        labels: m.keys,
        datasets: [{
          label: get_title,
          data: m.values,
          backgroundColor: chart_colors
        }]
      },
      options: {}
    };

  end

  def chart_colors
    ['red','yellow','blue','orange','green','purple','brown','pink','gray','gold', 'cyan', 'magenta', 'silver', 'lavender','teal']
  end

  def get_chart(data, types, headers)
    return get_line_chart(data, types, headers) if is_line_chart
    return get_pie_chart(data, types, headers) if is_pie_chart
    nil
  end

  def get_title_with_pagination
    title = get_title
    pag = pagination
    unless pag.nil?
      title = "#{title} (Page #{@page})"
    end
    title
  end

  def get_alternative_queries_with_pagination
    qarr = get_alternative_queries
    pag = pagination
    unless pag.nil?
      if pag.key?(:prior_page)
        params = @myparams.clone
        params['page'] = pag[:prior_page]
        qarr.append({
          label: "Prev: Page #{@page-1}",
          url: params_to_str(params)
        })
      end
      if pag.key?(:next_page)
        params = @myparams.clone
        params['page'] = pag[:next_page]
        qarr.append({
          label: "Next: Page #{@page+1}",
          url: params_to_str(params)
        })
      end
    end
    qarr.prepend(get_this_query)
    qarr
  end

  def get_this_query
    {
      label: "This Query",
      url: params_to_str(@myparams.clone),
      class: "rerun"
    }
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

  def get_report_url(key)
    s3_client = Aws::S3::Client.new(region: 'us-west-2')
    s3bucket = @config['s3-bucket']
    signer = Aws::S3::Presigner.new
    url, headers = signer.presigned_request(
      :get_object, 
      bucket: s3bucket, 
      key: key
    )
    url
  end

  def num_format(n)
    return "" if n.nil?
    n.to_s.chars.to_a.reverse.each_slice(3).map(&:join).join(',').reverse
  end

  def log(message)
    LambdaBase.log_config(@config, message)
  end
end