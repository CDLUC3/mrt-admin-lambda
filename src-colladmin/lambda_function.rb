require_relative 'lambda_base'

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
require_relative 'actions/post_to_ingest_multipart_action.rb'

# Handle GET or POST event structures pass in via the ALB
def get_params_from_event(event)
  data = event ? event : {}
  method = data.fetch('httpMethod', 'GET')

  if (method == 'GET') then
     data_transform = data.fetch('queryStringParameters', data)
     # not needed
     data_transform.delete("splat")
     return data_transform.each { |k, v| data_transform[k] = CGI.unescape(v) }
  end

  if data['isBase64Encoded'] && data.key?('body')
    body = Base64.decode64(data['body'])
    return CGI::parse(body).transform_values(&:first)
  end
  body = data.fetch('body', '')
  return {} if body.empty?
  CGI::parse(body).transform_values(&:first)
end

module LambdaFunctions
  class Handler < LambdaBase
    def self.process(event:,context:)
      begin
        config_file = 'config/database.ssm.yml'
        config_block = ENV.key?('MERRITT_ADMIN_CONFIG') ? ENV['MERRITT_ADMIN_CONFIG'] : 'default'
        config = Uc3Ssm::ConfigResolver.new({
          def_value: 'N/A' 
        }).resolve_file_values({
          file: config_file, 
          return_key: config_block
        })
        collHandler = LambdaFunctions::Handler.new(config)
        respath = event.fetch("path", "")
        return collHandler.web_assets(respath) if collHandler.web_asset?(respath)

        data = event ? event : {}
        
        #myparams = get_key_val(data, 'queryStringParameters', data)
        myparams = collHandler.get_params_from_event(event)
        path = CGI.unescape(collHandler.get_key_val(myparams, 'path', 'na'))
        result = {message: "Path undefined"}.to_json

        if path == "profiles" 
          result = IngestProfileAction.new(config, path, myparams).get_data
        elsif path == "state" 
          result = IngestStateAction.new(config, path, myparams).get_data
        elsif path == "queues" 
          result = IngestQueueAction.new(config, path, myparams).get_data
        elsif path == "batch" 
          result = IngestBatchAction.new(config, path, myparams).get_data
        elsif path == "job" 
          result = IngestJobMetadataAction.new(config, path, myparams).get_data
        elsif path == "manifest" 
          result = IngestJobManifestAction.new(config, path, myparams).get_data
        elsif path == "files" 
          result = IngestJobFilesAction.new(config, path, myparams).get_data
        elsif path == "batchFolders" 
          result = IngestBatchFoldersAction.new(config, path, myparams).get_data
        elsif path == "sword" 
          result = IngestSwordJobsAction.new(config, path, myparams).get_data
        elsif path == "submissions/pause" 
          result = PostToIngestAction.new(config, path, myparams, "admin/submissions/freeze").get_data
        elsif path == "submissions/unpause" 
          result = PostToIngestAction.new(config, path, myparams, "admin/submissions/thaw").get_data
        elsif path == "createProfile/profile" 
          result = PostToIngestMultipartAction.new(config, path, myparams, "admin/profile/profile").get_data
        elsif path == "createProfile/collection" 
          result = PostToIngestMultipartAction.new(config, path, myparams, "admin/profile/collection").get_data
        elsif path == "createProfile/owner" 
          result = PostToIngestMultipartAction.new(config, path, myparams, "admin/profile/owner").get_data
        elsif path == "createProfile/sla" 
          result = PostToIngestMultipartAction.new(config, path, myparams, "admin/profile/sla").get_data
        elsif path =~ /ldap\/.*/ 
          result = LDAPAction.make_action(config, path, myparams).get_data
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

    def initialize(config)
      super(config)
    end

     
    def template_parameters(path)
      map = super(path)
      return default_template_parameters if path == "/web/profile.js"
      if path == '/web/collProfile.html'
        map['OWNERS'] = Owners.new(@config).owners
        map['NODES'] = Nodes.new(@config).nodes
        profiles = IngestProfileAction.new(@config, "", {}).get_profile_list
        map['NOTIFICATIONS'] = profiles.notification_map
        map['RECENTCOLLS'] = profiles.recent_profiles
        formenv = ENV.fetch("FORMENV",'')
        # special path handling for DEV env
        map['FORMENV'] = formenv == 'development' ? '' : formenv
        map['SLAS'] = Collections.new(@config, "MRT-service-level-agreement").collections_select
      end
      map
    end
  end

end
