require 'json'
require 'yaml'
require 'uc3-ssm'
require 'httpclient'

require_relative 'actions/action'
require_relative 'actions/all_profiles'
require_relative 'actions/compare_profiles'

def get_key_val(obj, key, defval='')
  return "" unless obj
  return obj[key] if obj[key]
  return obj[key.to_sym] if obj[key.to_sym]
  defval
end

def get_config
  config_file = 'config/database.ssm.yml'
  config_file = "../src/#{config_file}" unless File.file?(config_file)
  config_block = ENV.key?('MERRITT_ADMIN_CONFIG') ? ENV['MERRITT_ADMIN_CONFIG'] : 'default'
  Uc3Ssm::ConfigResolver.new({
    def_value: 'N/A' 
  }).resolve_file_values({
    file: config_file, 
    return_key: config_block
  })
end

module LambdaFunctions
  class Handler
    def self.process(event:,context:)
      begin
        @config = get_config

        data = event ? event : {}
        
        myparams = get_key_val(data, 'queryStringParameters', data)
        path = get_key_val(myparams, 'path', 'na')
        result = {message: "Path undefined"}

        if path == "profiles"
          if myparams.fetch('profile', '') == ''
            result = AllProfiles.new(@config, path, myparams).get_data
          else
            result = CompareProfiles.new(@config, path, myparams).get_data
          end
        elsif path == "state" && get_ingest_server != ''
          cli = HTTPClient.new
          url = "#{get_ingest_server}state"
          resp = cli.get(url, event, {"Accept": "application/json"})
          result = {message: "Status #{resp.status}; URL: #{url}"}
        end
     
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

    def self.get_ingest_server
      @config.fetch('ingest-services', '').split(',').first
    end
  
  end

end
