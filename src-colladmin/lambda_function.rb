require 'json'
require 'yaml'
require 'uc3-ssm'

require_relative 'actions/action'
require_relative 'actions/all_profiles'
require_relative 'actions/compare_profiles'
require_relative 'actions/forward_to_ingest_action'
require_relative 'actions/ldap_action'

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
        result = {message: "Path undefined"}.to_json

        if path == "s3profiles" && myparams.fetch('profile', '') == ''
          result = AllProfiles.new(@config, path, myparams).get_data
        elsif path == "s3profiles"
          result = CompareProfiles.new(@config, path, myparams).get_data
        elsif path == "profiles" 
          result = ForwardToIngestAction.new(@config, path, myparams, "admin/#{path}").get_data
        elsif path == "state" 
          result = ForwardToIngestAction.new(@config, path, myparams, "state").get_data
        elsif path == "queues" 
          result = ForwardToIngestAction.new(@config, path, myparams, "admin/#{path}").get_data
        elsif path == "submissions/pause" 
          result = ForwardToIngestAction.new(@config, path, myparams, "admin/#{path}").get_data
        elsif path == "submissions/unpause" 
          result = ForwardToIngestAction.new(@config, path, myparams, "admin/#{path}").get_data
        elsif path == "ldap/users" 
          result = LDAPAction.new(@config, path, myparams).get_data
        elsif path == "ldap/roles" 
          result = LDAPAction.new(@config, path, myparams).get_data
        end
     
        {
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json; charset=utf-8'
          },
          statusCode: 200,
          body: result
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
