require 'yaml'
require 'aws-sdk-ssm'
require "base64"

class ConsistencyDriver
    def initialize(mode, awscli_ver)
        @config = YAML.load_file('reports.yml')
        @awscli_ver = awscli_ver
        region = ENV['AWS_REGION'] || 'us-west-2'
        @ssm_root_path = ENV['SSM_ROOT_PATH'] || ''
        @mode = mode
        @tmpfile = "/tmp/adminrpt.#{@mode}.txt"

        @client = Aws::SSM::Client.new(region: region)
        @admintool = get_parameter("admintool/lambda-arn-base", mode)
        @colladmin = get_parameter("colladmin/lambda-arn-base", mode)
    end

    def get_parameter(key, suffix)
        fullkey = "#{@ssm_root_path}#{key}"
        val = @client.get_parameter(name: fullkey)[:parameter][:value]
        "#{val}-#{suffix}"
    end

    def invoke_lambda(arn, params)
        payload = @awscli_ver == 'v2' ? Base64.encode64(params.to_json) : params.to_json
        cmd = "aws lambda invoke --function #{arn} --payload '#{payload}' #{@tmpfile} | jq .StatusCode"
        cmdstat = %x( #{cmd} ).strip!
        cmdout = %x( jq '.body' #{@tmpfile} | jq -r . | jq .report_path )
        puts "\t#{cmdstat}: #{cmdout}"
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
    ARGV.length > 0 ? ARGV[0] : 'dev',
    ARGV.length > 1 ? ARGV[1] : 'v2',
)
driver.run