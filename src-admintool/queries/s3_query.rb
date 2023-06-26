require 'tempfile'

class S3AdminQuery < AdminQuery
  def initialize(query_factory, path, myparams)
    super(query_factory, path, myparams)
    @csvlen = 0
    @message = ""
    @report = 'merritt-reports/temp.csv'
  end

  def save_query_to_s3
    sql = get_sql
    stmt = @client.prepare(sql)
    query_params = get_params
    @results = stmt.execute(*query_params)
    tf = Tempfile.new('temp.csv')
    create_result_csv(@results, tf)
    save_data_report(@report, tf)
    @message = "Report created (#{@report}).  #{num_format(@csvlen)} records. #{num_format(tf.length)} bytes."
    tf.unlink
    message_as_table(@message)
  end

  def run_sql
    save_query_to_s3
  end

  def create_result_csv(results, tf)
    types = get_types([[]])
    headers = get_headers([[]])
    headers.each_with_index do |h, i|
      tf.write(',') unless i == 0
      tf.write("\"#{h}\"")
    end
    tf.write("\n")
    results.each do |r|
      @csvlen += 1
      # puts @csvlen if @csvlen % 100000 == 0
      r.values.each_with_index do |c,i|
        tf.write(",") unless i == 0
        tf.write("\"#{c}\"")
      end
      tf.write("\n")
    end
  end

  def get_alternative_queries
    [
      {
        label: "Download Report", 
        url: get_report_url(@report),
        class: 'download'
      }
    ]
  end
end