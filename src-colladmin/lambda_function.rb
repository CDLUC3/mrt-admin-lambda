require_relative 'lambda_base'

require_relative 'actions/action'
require_relative 'actions/forward_to_ingest_action'
require_relative 'actions/ingest_queue_action'
require_relative 'actions/inventory_queue_action'
require_relative 'actions/access_queue_action'
require_relative 'actions/ingest_state_action'
require_relative 'actions/ingest_profile_action'
require_relative 'actions/admin_profile_action'
require_relative 'actions/ingest_batch_action'
require_relative 'actions/ingest_job_metadata_action'
require_relative 'actions/ingest_job_manifest_action'
require_relative 'actions/ingest_job_files_action'
require_relative 'actions/ingest_sword_jobs_action'
require_relative 'actions/ingest_batch_folders_action'
require_relative 'actions/ldap_action'
require_relative 'actions/post_to_ingest_action'
require_relative 'actions/post_to_ingest_multipart_action.rb'
require_relative 'actions/cognito_action.rb'
require_relative 'actions/storage_action.rb'
require_relative 'actions/tag_action.rb'
require_relative 'actions/ssm_describe_action.rb'

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
        collHandler = LambdaFunctions::Handler.new(config, event, context.client_context)
        # Read the notes in LambdaBase for a description of how authentication is performed
        # A unique exception will be called if the user/client cannot authenticate
        # The Collection Admin tool also has code in place that can manage particiation in Cognito user groups. 
        # See cognito_action.rb for details.
        collHandler.check_permission
  
        respath = event.fetch("path", "")
        myparams = collHandler.get_params_from_event(event)
        return collHandler.web_assets("/web/favicon.ico", myparams) if respath =~ %r[^/(favicon.ico).*]
        return collHandler.web_assets(respath, myparams) if collHandler.web_asset?(respath)

        data = event ? event : {}
        
        #myparams = get_key_val(data, 'queryStringParameters', data)
        path = CGI.unescape(collHandler.get_key_val(myparams, 'path', 'na'))
        result = {message: "Path undefined"}.to_json

        if path == "profiles" 
          result = IngestProfileAction.new(config, path, myparams).get_data
        elsif path == "adminprofiles" 
          result = AdminProfileAction.new(config, path, myparams).get_data
        elsif path == "state" 
          result = IngestStateAction.new(config, path, myparams).get_data
        elsif path == "queues" 
          result = IngestQueueAction.new(config, path, myparams).get_data
        elsif path == "inv-queues" 
          result = InventoryQueueAction.new(config, path, myparams).get_data
        elsif path == "acc-queues" 
          result = AccessQueueAction.new(config, path, myparams).get_data
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
        elsif path == "submit-profile" 
          params = {
            file: File.new("/var/task/dummy.README"),
            type: "file",
            submitter: myparams.fetch("submitter", ""),
            responseForm: "xml",
            title: myparams.fetch("title", ""),
            profile: myparams.fetch("profile-path", "")
          }
          result = PostToIngestMultipartAction.new(config, path, params, "poster/update").get_data
          return {
            headers: {
              'Access-Control-Allow-Origin': '*',
              'Content-Type': 'application/xml; charset=utf-8'
            },
            statusCode: 200,
            body: result
          }
        elsif path == "toggle_harvest" || path == "set_mnemonic" || path == "set_coll_name" || path == "set_sla_name" || path == "set_own_name" || path == "create_owner_record" || path == "create_coll_record"
          apa = AdminProfileAction.new(config, path, myparams)
          result = apa.perform_action
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
        elsif path == "cognito-users" 
          result = CognitoAction.new(config, path, myparams).get_data
        elsif path == "cognito-remove-user-from-group" 
          result = CognitoAction.new(config, path, myparams).get_data
        elsif path == "cognito-add-user-to-group" 
          result = CognitoAction.new(config, path, myparams).get_data
        elsif path == "instances" 
          result = TagAction.new(config, path, myparams).get_data
        elsif path == "ssm-describe" 
          result = SsmDescribeAction.new(config, path, myparams).get_data
        elsif path == "unpause-ingest-for-collection" 
          result = LambdaBase.jsredirect("https://cdluc3.github.io/mrt-doc/diagrams/store-admin-pause-ing-for-coll")
        elsif path == "pause-ingest-for-collection" 
          result = LambdaBase.jsredirect("https://cdluc3.github.io/mrt-doc/diagrams/store-admin-pause-ing-for-coll")
        elsif path == "storage-force-audit-for-object" 
          result = StorageAction.new(config, path, myparams).perform_action
        elsif path == "storage-rerun-audit-for-object" 
          result = StorageAction.new(config, path, myparams).perform_action
        elsif path == "storage-force-replic-for-object" 
          result = StorageAction.new(config, path, myparams).perform_action
        elsif path == "storage-clear-audit-batch" 
          result = StorageAction.new(config, path, myparams).perform_action
        elsif path == "storage-add-node-for-collection" 
          result = LambdaBase.jsredirect("https://cdluc3.github.io/mrt-doc/diagrams/store-admin-add-node")
        elsif path == "storage-del-node-for-collection" 
          result = LambdaBase.jsredirect("https://cdluc3.github.io/mrt-doc/diagrams/store-admin-del-node")
        elsif path == "storage-del-object-from-node" 
          result = LambdaBase.jsredirect("https://cdluc3.github.io/mrt-doc/diagrams/store-admin-del-node-obj")
        elsif path == "storage-change-primary-for-collection" 
          result = LambdaBase.jsredirect("https://cdluc3.github.io/mrt-doc/diagrams/store-admin-change-primary-node")
        elsif path == "storage-reroute-ui-for-collection" 
          result = LambdaBase.jsredirect("https://cdluc3.github.io/mrt-doc/diagrams/store-admin-reroute-ui")
        elsif path == "storage-scan-node" 
          result = LambdaBase.jsredirect("https://cdluc3.github.io/mrt-doc/diagrams/store-admin-scan-node")
        elsif path == "storage-review" 
          result = LambdaBase.jsredirect("https://cdluc3.github.io/mrt-doc/diagrams/store-admin-scan-node")
         elsif path == "storage-delete-node-key" 
          result = LambdaBase.jsredirect("https://cdluc3.github.io/mrt-doc/diagrams/store-admin-del-node-keys")
        elsif path == "storage-delete-obj" 
          result = LambdaBase.jsredirect("https://cdluc3.github.io/mrt-doc/diagrams/store-admin-del-obj")
        end
     
        {
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json; charset=utf-8'
          },
          statusCode: 200,
          body: result
        }
      rescue PermissionDeniedError => e
        puts(e.message)
        return LambdaBase.error(401, e.message, false)
      rescue => e
        puts(e.message)
        puts(e.backtrace)
        return LambdaBase.error(500, e.message, false)
      end

    end

    def initialize(config, event, context)
      super(config, event, context)
    end

    def self.merritt_admin_owner
      "ark:/13030/j2rn30xp"
    end

    def self.merritt_admin_coll_sla
      "ark:/13030/j2h41690"
    end

    def self.merritt_admin_coll_owners
      "ark:/13030/j2cc0900"
    end

    def self.merritt_curatorial
      "ark:/13030/j27p88qw"
    end

    def self.merritt_system
      "ark:/13030/j2mw23mp"
    end

    def template_parameters(path, myparams)
      map = super(path, myparams)
      if path == '/web/collProfile.html'
        map['OWNERS'] = Owners.new(@config).objs_select
        map['NODES'] = Nodes.new(@config).nodes
        profiles = IngestProfileAction.new(@config, "", {}).get_profile_list
        map['NOTIFICATIONS'] = profiles.notification_map
        # when constructing the admin object hierarchy, the parent object will first exist only in the inv_objects table
        map['COLLS'] = CollectionObjs.new(@config).objs_select
        formenv = ENV.fetch("FORMENV",'')
        # special path handling for DEV env
        map['FORMENV'] = formenv == 'development' ? '' : formenv
        map['SLAS'] = Slas.new(@config).objs_select
      elsif path == "/web/properties.js"
      elsif path == "/web/profile.js"
        map['ADMIN_OWNER'] = LambdaFunctions::Handler.merritt_admin_owner
      elsif path == '/web/collAdminObjs.html'
        artifact = myparams.fetch("type", "")
        map['artifact'] = artifact
        map["artifact_#{artifact}"] = true
        profiles = AdminProfileAction.new(@config, "adminprofiles", myparams).get_profile_list
        map['NEWOBJS'] = []
        profiles.each do |p|
          map['NEWOBJS'].append(p) unless p.adsub_status == 'SKIP'
        end
       elsif path == '/web/artifactProperties.html'
        artifact = myparams.fetch("type", "")
        map['artifact'] = artifact
        map["artifact_#{artifact}"] = true
        profiles = AdminProfileAction.new(@config, "adminprofiles", myparams).get_profile_list
        map['COLLS'] = []
        profiles.each do |p|
          map['COLLS'].append(p) unless p.addb_status == 'SKIP'
        end
      elsif path == '/web/storeCollNodes.html'
        colls = Collections.new(@config)
        colls.merge_profiles
        map['COLLS'] = colls.collections_select
      elsif path == '/web/storeCollNode.html'
        coll = myparams.fetch("coll", "")
        name = myparams.fetch("name", "")
        primary_node = myparams.fetch("primary_node", "")
        map['COLLNAME'] = CGI.unescape(name)
        map['PRIMARY_NODE'] = primary_node
        map['COLL'] = coll.to_i
        map['ingest_paused'] = false
        map['CNODES'] = CollectionNodes.new(@config, coll.to_i, primary_node).collnodes         
        map['NODES'] = Nodes.new(@config).nodes
      elsif path == '/web/storeNodes.html'
        map['NODES'] = Nodes.new(@config).nodes
      elsif path == '/web/storeNodeDeletes.html'
      elsif path == '/web/storeObjects.html'
        objlist = CGI.unescape(myparams.fetch("objlist",""))
        mode = myparams.fetch("mode", "")
        owner = myparams.fetch("owner", "")
        map['OWNERS'] = Owners.new(@config, owner).objs_select
        map['OBJLIST'] = objlist
        map['ISARK'] = mode == "ark"
        map['ISLOC'] = mode == "localid"
        map['ISID'] = mode == "id"
        objects = ObjectQuery.query_factory(
          @config,
          mode,
          objlist,
          owner
        ).objects
        map['OBJS'] = objects
        map['OBJSCNT'] = objects.length
      elsif path == '/web/storeObjectNodes.html'
        id = myparams.fetch("id","0").to_i
        map['ID'] = id
        map['OBJNODES'] = ObjectNodes.new(@config, id).nodes
      end
      map
    end
  end

end
