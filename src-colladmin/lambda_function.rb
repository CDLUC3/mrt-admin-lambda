require_relative 'lambda_base'

require_relative 'actions/action'
require_relative 'actions/forward_to_ingest_action'
require_relative 'actions/ingest_queue_action'
require_relative 'actions/ingest_queue_profile_action'
require_relative 'actions/inventory_queue_action'
require_relative 'actions/access_queue_action'
require_relative 'actions/ingest_state_action'
require_relative 'actions/ingest_profile_action'
require_relative 'actions/ingest_collection_locks_action'
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
require_relative 'actions/queue_action'
require_relative 'actions/submit_profile_action'
require_relative 'actions/cognito_action.rb'
require_relative 'actions/storage_action.rb'
require_relative 'actions/tag_action.rb'
require_relative 'actions/ssm_describe_action.rb'
require_relative 'actions/replication_action.rb'
require_relative 'actions/ingest_lock_action.rb'
require 'yaml'

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
  class ActionFactory
    def initialize(config)
      @config = config
      @actions = YAML.load_file("config/actions.yml")
    end  

    def get_action_def(path)
      @actions.fetch(path, {class: AdminAction, description: "Report not found", implemented: false})
    end
  
    def supported?(path)
      action_def = get_action_def(path)
      supported = action_def.fetch("implemented", true)
      supported = supported & action_def.fetch("prod_support", true) if LambdaBase.is_prod
      supported
    end

    def get_action_for_path(path, myparams)
      action = get_action_def(path)
      params = action.fetch('params', [])
  
      # Use Ruby metaprogramming to construct the report class
      if params.length == 2
        Object.const_get(action['class']).new(@config, action, path, myparams, params[0], params[1])
      elsif params.length == 1
        Object.const_get(action['class']).new(@config, action, path, myparams, params[0])
      else
        Object.const_get(action['class']).new(@config, action, path, myparams)
      end
    end  
  end

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
        puts(respath)
        myparams = collHandler.get_params_from_event(event)
        puts(myparams)
        return collHandler.web_assets("/web/favicon.ico", myparams) if respath =~ %r[^/(favicon.ico).*]
        return collHandler.web_assets(respath, myparams) if collHandler.web_asset?(respath)

        data = event ? event : {}
        
        #myparams = get_key_val(data, 'queryStringParameters', data)
        path = CGI.unescape(collHandler.get_key_val(myparams, 'path', 'na'))
        result = {message: "Path undefined"}.to_json

        content_type = "application/json; charset=utf-8"

        action_factory = ActionFactory.new(config)

        action = action_factory.get_action_for_path(path, myparams)
        result = action.perform_action if action_factory.supported?(path)
     
        {
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': content_type
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
      map['COLL_LAMBDABASE_JS'] = Mustache.render(File.open("template/coll-lambda.base.js").read, map)
      map['PROFILE_JS'] = Mustache.render(File.open("template/profile.js").read, map)
      map['SUBPROFILE_JS'] = Mustache.render(File.open("template/subprofile.js").read, map)
      map['PROPERTIES_JS'] = Mustache.render(File.open("template/properties.js").read, map)
      map['STORAGE_JS'] = Mustache.render(File.open("template/storage.js").read, map)
      if path == '/web/collProfile.html'
        map['OWNERS'] = Owners.new(@config).objs_select
        map['NODES'] = Nodes.new(@config).nodes
        profiles = IngestProfileAction.new(@config, {}, "", {}).get_profile_list
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
        profiles = AdminProfileAction.new(@config, {}, "adminprofiles", myparams).get_profile_list
        map['NEWOBJS'] = []
        profiles.each do |p|
          map['NEWOBJS'].append(p) unless p.adsub_status == 'SKIP'
        end
       elsif path == '/web/artifactProperties.html'
        artifact = myparams.fetch("type", "")
        map['artifact'] = artifact
        map["artifact_#{artifact}"] = true
        profiles = AdminProfileAction.new(@config, {}, "adminprofiles", myparams).get_profile_list
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
        info = CollectionNodeInfo.new(@config, coll.to_i)
        primary_node = info.primary_node
        map['COLLNAME'] = info.name
        map['COLL'] = coll.to_i
        map['ingest_paused'] = false
        map['CNODES'] = CollectionNodes.new(@config, coll.to_i, primary_node).collnodes         
        map['NODES'] = []
        skips = {}
        map['CNODES'].each do |coll|
          n = coll[:number].to_s
          skips[n] = true
        end
        Nodes.new(@config).nodes.each do |node|
          n = node[:number].to_s
          map['NODES'].append(node) unless skips[n]
        end
        map['CNODES_CLEANUP'] = CollectionNodeCleanup.new(@config, coll).nodes
      elsif path == '/web/storeNodes.html'
        nodenum = myparams.fetch("nodenum", "0").to_i
        nodename = CGI.unescape(myparams.fetch("nodename", ""))
        map['nodenum'] = nodenum
        map['nodename'] = nodename
        map['NODES'] = Nodes.new(@config).nodes
      elsif path == '/web/storeScans.html'
        nodenum = myparams.fetch("nodenum", "0").to_i
        map['nodenum'] = nodenum
        map['SCANS'] = Scans.new(@config, nodenum).scans
      elsif path == '/web/storeNodeReview.html'
        nodenum = myparams.fetch("nodenum", "0").to_i
        scanid = myparams.fetch("scanid", "0").to_i
        maint_status = myparams.fetch("maint_status", "review")
        maint_src = ScanReviewCounts.new(@config, nodenum, maint_status)
        map['mcount'] = nodenum == 0 ? "na" : maint_src.mcount
        map['mcount_fmt'] = nodenum == 0 ? "na" : maint_src.mcount_fmt
        map['size_fmt'] = nodenum == 0 ? "na" : maint_src.msize_fmt
        map['maint_status'] = maint_status
        map['is_delete'] = maint_status == 'delete'
        map['is_review'] = maint_status == 'review'
        map['is_hold'] = maint_status == 'hold'
        map['scan_limit'] = myparams.fetch("limit", "100").to_i
        map['scan_limit'] = 1000 if map['scan_limit'] > 1000
        map['scan_offset'] = myparams.fetch("offset", "0").to_i
        map['scan_offset'] = 0 if map['scan_offset'] < 0
        map['nodenum'] = nodenum
        map['scanid'] = scanid
        rev = ScanReview.new(@config, maint_status)
        if scanid == 0
          rev.process_resuts(
            rev.nodenum_query(nodenum, map['scan_limit'], map['scan_offset'])
          )
        else
          rev.process_resuts(
            rev.scanid_query(scanid, map['scan_limit'], map['scan_offset'])
          )
        end
        map['REVIEW'] = rev.review_items
        map['scan_count'] = map['REVIEW'].length
        map['scan_next'] = (map['scan_count'] == map['scan_limit']) ? map['scan_offset'] + map['scan_limit'] : false
        map['scan_prev'] = (map['scan_offset'] > 0) ? (map['scan_offset'] > map['scan_limit'] ? map['scan_offset'] - map['scan_limit'] : 0) : false
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
        # id or ark can be use for lookup
        id = myparams.fetch("id","0").to_i
        if id == 0
          ark = CGI.unescape(myparams.fetch("ark",""))
          id = ObjectArk.new(@config, ark).id 
        end
        map['ID'] = id
        map['OBJNODES'] = ObjectNodes.new(@config, id).nodes
        objects = ObjectQuery.query_factory(
          @config,
          "id",
          id.to_s,
          ""
        ).objects
        map['OBJS'] = objects
      elsif path == '/web/describeActions.html'
        map['ACTIONS'] = getActionsList
      elsif path == '/web/navActions.html'
        map['ACTIONSMAP'] = getActionsMap
      elsif path == '/web/storeQueues.html'
        map['AUDIT_INFO'] = AuditInfo.new(@config).data
      end
      map
    end

    def description_doc(act)
      desc = act.fetch('description', '')
      doc = act.fetch('documentation', '')
      return desc if doc.empty?
      "#{desc}\n\n-- Technical Documentation --\n```\n#{doc}\n```"
    end

    def getActionsArr
      actions = YAML.load_file("config/actions.yml")
      actlist = []
      actions.keys.each do |k|
        act = actions[k]
        actlist.append({
          action: k,
          title: act.fetch('link-title', '--'), 
          path: act.fetch('nav', {}).fetch('path', ''), 
          class: act.fetch('class', 'Undefied'), 
          description: act.fetch('description', ''), 
          description_doc: description_doc(act),
          documentation: act.fetch('documentation', ''), 
          implemented: act.fetch('implemented', true), 
          prod_support: act.fetch('prod_support', true), 
          sensitivity: act.fetch('sensitivity', ''), 
          is_readonly: act.fetch('sensitivity', '') == 'readonly',
          category: act.fetch('category', ''), 
          testing: act.fetch('testing_instructions', act.fetch('testing', '')), 
        })
      end
      actlist
    end
  
    def getActionsList
      actlist = getActionsArr
      actlist.sort!{
        |a,b| "#{a[:path]}/#{a[:report]}" <=> "#{b[:path]}/#{b[:report]}"  
      }
      actlist
    end

    def getActionsMap
      actmap = {}
      getActionsArr.each do |act|
        path = act.fetch(:path, '')
        actmap[path] = [] unless actmap.key?(path)
        actmap[path].push(act)
      end
      maplist = []
      actmap.keys.sort.each do |p|
        maplist.push({path: p, actions: actmap[p]})
      end
      maplist
    end
  end

end
