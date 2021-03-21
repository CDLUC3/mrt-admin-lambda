require 'json'
require 'yaml'
require 'uc3-ssm'
require 'mysql2'
require "base64"
require "cgi"
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
  method = data.fetch('httpMethod', 'GET')

  return data.fetch('queryStringParameters', data) if method == 'GET'

  if data['isBase64Encoded'] && data.key?('body')
    body = Base64.decode64(data['body'])
    return CGI::parse(body).transform_values(&:first)
  end
  body = data.fetch('body', '')
  return {} if body.empty?            
  CGI::parse(body).transform_values(&:first)
end


def get_mysql(dbconf)
  raise Exception.new "Configuration username not found" unless dbconf['username']
  raise Exception.new "Configuration password not found" unless dbconf['password']
  raise Exception.new "Configuration database not found" unless dbconf['database']
  raise Exception.new "Configuration host not found" unless dbconf['host']
  raise Exception.new "Configuration port not found" unless dbconf['port']

  Mysql2::Client.new(
    :host => dbconf['host'],
    :username => dbconf['username'],
    :database=> dbconf['database'],
    :password=> dbconf['password'],
    :port => dbconf['port'],
    :encoding => dbconf.fetch('encoding', 'utf8mb4'),
    :collation => dbconf.fetch('collation', 'utf8mb4_unicode_ci'),
  )
end

module LambdaFunctions
  class Handler
    def self.process(event:,context:)
      begin
        config_file = 'config/database.ssm.yml'
        config_file = "../src/#{config_file}" unless File.file?(config_file)
        config_block = ENV.key?('MERRITT_ADMIN_CONFIG') ? ENV['MERRITT_ADMIN_CONFIG'] : 'default'
        @config = Uc3Ssm::ConfigResolver.new.resolve_file_values(file: config_file, resolve_key: config_block, return_key: config_block)
        dbconf = @config.fetch('dbconf', {})
        client = get_mysql(dbconf)

        myparams = get_params_from_event(event)
        puts(myparams)

        path = get_key_val(myparams, 'path', 'na')
        query_factory = QueryFactory.new(client, @config['merritt_path'])
        query = query_factory.get_query_for_path(path, myparams)
        result = query.run_sql
     
        {
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json; charset=UTF-8'
          },
          statusCode: 200,
          body: result.to_json
        }
      rescue => e
        puts(e.message)
        puts(e.backtrace)
        {
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json; charset=UTF-8'
          },
          statusCode: 500,
          body: { error: e.message }.to_json
        }
      end
    end
  end
end
