require 'json'
require 'yaml'
require 'uc3-ssm'
require 'mysql2'
require "base64"
require_relative 'queries/query'
require_relative 'queries/query_factory'

def get_key_val(obj, key, defval='')
  return "" unless obj
  return obj[key] if obj[key]
  return obj[key.to_sym] if obj[key.to_sym]
  defval
end

# Handle GET or POST event structures pass in via the ALB
def get_params_from_event(event)
  data = event ? event : {}

  puts(data)
  return data.fetch('queryStringParameters', data) unless data.key?('body')

  if data['isBase64Encoded'] && data.key?('body')
    puts(222)
    body = Base64.decode64(data['body'])
    puts(body)
    return JSON.parse(body)
  end
  puts(3333)
  body = data.fetch('body', '')
  puts(body)
  return {} if body.empty?            
  JSON.parse(body)
end


def get_mysql
  raise Exception.new "The configuration yaml must contain config['dbconf']" unless @config['dbconf']
  dbconf = @config['dbconf']
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

module LambdaFunctions
  class Handler
    def self.process(event:,context:)
      begin
        config_file = 'config/database.ssm.yml'
        config_file = "../src/#{config_file}" unless File.file?(config_file)
        config_block = ENV.key?('MERRITT_ADMIN_CONFIG') ? ENV['MERRITT_ADMIN_CONFIG'] : 'default'
        @config = Uc3Ssm::ConfigResolver.new.resolve_file_values(file: config_file, resolve_key: config_block, return_key: config_block)
        client = get_mysql

        myparams = get_params_from_event(event)

        path = get_key_val(myparams, 'path', 'na')
        query_factory = QueryFactory.new(client, @config['merritt_path'])
        query = query_factory.get_query_for_path(path, myparams)
        result = query.run_sql
     
        {
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json; charset=utf-8'
          },
          statusCode: 200,
          body: result.to_json
        }
      rescue => e
        {
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json; charset=utf-8'
          },
          statusCode: 500,
          body: { error: e.message }.to_json
        }
      end
    end
  end
end
