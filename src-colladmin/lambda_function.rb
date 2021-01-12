require 'json'
require 'yaml'
require 'uc3-ssm'
require 'mysql2'

require_relative 'actions/action'

def get_key_val(obj, key, defval='')
  return "" unless obj
  return obj[key] if obj[key]
  return obj[key.to_sym] if obj[key.to_sym]
  defval
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
        #client = get_mysql

        data = event ? event : {}
        
        myparams = get_key_val(data, 'queryStringParameters', data)
        path = get_key_val(myparams, 'path', 'na')
        action = AdminAction.new(client, @config['merritt_path'], path, myparams)

        result = action.get_data
     
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
