require 'json'
#equire 'aws-sdk-ssm'
#require 'aws-sdk-lambda'
require 'yaml'
require 'mysql2'
require_relative 'queries/query'
require_relative 'queries/query_factory'

def mformat(obj, key)
  return "" unless obj
  return obj[key] if obj[key]
  return obj[key.to_sym] if obj[key.to_sym]
  ""
end

def getSsmPath(arn)
  lambda = Aws::Lambda::Client.new
  #lambda.list_tags({resource: arn})
  '/uc3/mrt/stg/'
rescue
  '/uc3/mrt/stg/'
end

def getSsmVal(ssm, root, path)
  ssm.get_parameter(name: "#{root}#{path}")[:parameter][:value]
end

def get_mysql(arn)
  ssmpath = getSsmPath(arn)
  ssm = Aws::SSM::Client.new
  db_user = getSsmVal(ssm, ssmpath, 'billing/readonly/db-user')
  db_password = getSsmVal(ssm, ssmpath, 'billing/readonly/db-password')
  db_name = getSsmVal(ssm, ssmpath, 'billing/db-name')
  db_host = getSsmVal(ssm, ssmpath, 'billing/db-host')

  Mysql2::Client.new(
    :host => db_host,
    :username => db_user,
    :database=> db_name,
    :password=> db_password,
    :port => 3306)
rescue
  config = load_config('database.yml')['stage']
  db_user = config['username']
  db_password = config['password']
  db_host = config['host']
  db_name = config['database']

  Mysql2::Client.new(
    :host => db_host,
    :username => db_user,
    :database=> db_name,
    :password=> db_password,
    :port => 3306)
end

def lambda_handler(event:, context:)
    arn = context['invoked_function_arn']
    client = get_mysql(arn)
    path = mformat(event, 'path')
    #mformat(event, 'queryStringParameters')

    query_factory = QueryFactory.new(client)
    query = query_factory.get_query_for_path(path)
    params = []
    json = query.run_sql.to_json

    {
      statusCode: 200,
      body: json
    }
    #JSON.generate('Hello from Lambda!')
end

def load_config(name)
  path = File.join('config', name)
  raise Exception, "Config file #{name} not found!" unless File.exist?(path)
  raise Exception, "Config file #{name} is empty!" if File.size(path) == 0

  conf     = YAML.load_file(path)
end
