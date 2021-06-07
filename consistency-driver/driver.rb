require 'yaml'
require 'aws-sdk-ssm'
require 'aws-sdk-lambda'
require "base64"

class ConsistencyDriver
    def initialize(mode)
        @config = YAML.load_file('reports.yml')
        region = ENV['AWS_REGION'] || 'us-west-2'
        @ssm_root_path = ENV['SSM_ROOT_PATH'] || ''
        @mode = mode
        @tmpfile = "/tmp/adminrpt.#{@mode}.txt"

        @client = Aws::SSM::Client.new(region: region)
        @admintool = get_parameter("admintool/lambda-arn-base", mode).gsub(/^.*function:/,'')
        @colladmin = get_parameter("colladmin/lambda-arn-base", mode).gsub(/^.*function:/,'')
        @lambda = Aws::Lambda::Client.new(region: region)
    end

    def get_parameter(key, suffix)
        fullkey = "#{@ssm_root_path}#{key}"
        val = @client.get_parameter(name: fullkey)[:parameter][:value]
        "#{val}-#{suffix}"
    end

    def invoke_lambda(arn, params)
        begin
            resp = @lambda.invoke({
                function_name: arn, 
                payload: params.to_json 
            })
            puts resp.status_code
            rbody = resp.payload.read
            rj = JSON.parse(JSON.parse(rbody).fetch("body", {}.to_json))
            puts rj.fetch("report_path","n/a")
        rescue => e
            puts(e.message)
        end
        sleep 2
    end

    def run 
        puts @admintool
        puts @colladmin
        @config.fetch("admintool", {}).fetch("daily", []).each do |query|
            puts "#{query}"
            invoke_lambda(@admintool, query)
        end
        @config.fetch("colladmin", {}).fetch("daily", []).each do |query|
            puts "#{query}"
            invoke_lambda(@colladmin, query)
        end
    end
end

puts ARGV
driver = ConsistencyDriver.new(
    ARGV.length > 0 ? ARGV[0] : 'dev'
)
driver.run