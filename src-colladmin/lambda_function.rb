require 'json'
require 'yaml'
require 'uc3-ssm'

require_relative 'actions/action'
require_relative 'actions/forward_to_ingest_action'
require_relative 'actions/ingest_queue_action'
require_relative 'actions/ingest_state_action'
require_relative 'actions/ingest_profile_action'
require_relative 'actions/ingest_batch_action'
require_relative 'actions/ingest_job_metadata_action'
require_relative 'actions/ingest_job_manifest_action'
require_relative 'actions/ingest_job_files_action'
require_relative 'actions/ingest_sword_jobs_action'
require_relative 'actions/ingest_batch_folders_action'
require_relative 'actions/ldap_action'
require_relative 'actions/post_to_ingest_action'

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
        path = CGI.unescape(get_key_val(myparams, 'path', 'na'))
        result = {message: "Path undefined"}.to_json

        if path == "profiles" 
          result = IngestProfileAction.new(@config, path, myparams).get_data
        elsif path == "state" 
          result = IngestStateAction.new(@config, path, myparams).get_data
        elsif path == "queues" 
          result = IngestQueueAction.new(@config, path, myparams).get_data
        elsif path == "batch" 
          result = IngestBatchAction.new(@config, path, myparams).get_data
        elsif path == "job" 
          result = IngestJobMetadataAction.new(@config, path, myparams).get_data
        elsif path == "manifest" 
          result = IngestJobManifestAction.new(@config, path, myparams).get_data
        elsif path == "files" 
          result = IngestJobFilesAction.new(@config, path, myparams).get_data
        elsif path == "batchFolders" 
          result = IngestBatchFoldersAction.new(@config, path, myparams).get_data
        elsif path == "sword" 
          result = IngestSwordJobsAction.new(@config, path, myparams).get_data
        elsif path == "submissions/pause" 
          result = PostToIngestAction.new(@config, path, myparams, "admin/submissions/freeze").get_data
        elsif path == "submissions/unpause" 
          result = PostToIngestAction.new(@config, path, myparams, "admin/submissions/thaw").get_data
        elsif path == "ldap/users" 
          result = LDAPAction.new(@config, path, myparams).get_data
        elsif path == "ldap/roles" 
          result = LDAPAction.new(@config, path, myparams).get_data
        elsif path == "ldap/coll" 
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
        puts(e.message)
        puts(e.backtrace)
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
