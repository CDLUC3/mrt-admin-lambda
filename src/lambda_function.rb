require 'json'
require 'aws-sdk-ssm'
require 'aws-sdk-lambda'
require 'yaml'
require 'uc3-ssm'
require 'mysql2'
require_relative 'queries/query'
require_relative 'queries/query_factory'

def get_key_val(obj, key, defval='')
  return "" unless obj
  return obj[key] if obj[key]
  return obj[key.to_sym] if obj[key.to_sym]
  defval
end


def get_mysql
  raise Exception.new "The configuration yaml must contain config['default']['dbconf']" unless @config['default']['dbconf']
  dbconf = @config['default']['dbconf']
  raise Exception.new "Configuration username not found" unless dbconf['username']
  db_user = dbconf['username']
  raise Exception.new "Configuration password not found" unless dbconf['password']
  db_password = dbconf['password']
  raise Exception.new "Configuration database not found" unless dbconf['database']
  db_name = dbconf['database']
  raise Exception.new "Configuration host not found" unless dbconf['host']
  db_host = dbconf['host']
  raise Exception.new "Configuration port not found" unless dbconf['port']
  db_port = dbconf['port']

  Mysql2::Client.new(
    :host => db_host,
    :username => db_user,
    :database=> db_name,
    :password=> db_password,
    :port => db_port)
end

def lambda_handler(event:, context:)
  begin
    config_path = ENV.key?('MERRITT_ADMIN_CONFIG') ? ENV['MERRITT_ADMIN_CONFIG'] : 'config/database.ssm.yml'
    @config = Uc3Ssm::ConfigResolver.new.resolve_file_values(config_path)

    client = get_mysql
    path = get_key_val(event, 'path').gsub(/^\//, '')
    myparams = get_key_val(event, 'queryStringParameters', {})

    query_factory = QueryFactory.new(client, @config['default']['merritt_path'])
    query = query_factory.get_query_for_path(path, myparams)
    json = query.run_sql.to_json

    {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'content-type':'application/json; charset=utf-8'
      },
      statusCode: 200,
      body: json
    }
  rescue => e
    {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'content-type':'application/json; charset=utf-8'
      },
      statusCode: 500,
      body: { error: e.message, trace: e.backtrace }.to_json
    }
  end
end
