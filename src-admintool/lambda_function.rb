require 'mysql2'
require "base64"
require "cgi"
require 'aws-sdk-s3'
require_relative 'lambda_base'
require_relative 'queries/query'
require_relative 'queries/query_factory'

module LambdaFunctions
  class Handler < LambdaBase

    def self.process(event:,context:)
      $REQID = context.aws_request_id
      $TASKNAME = 'assets'
      $mcolls = []
      config = {}
      begin
        config_file = 'config/database.ssm.yml'
        config_block = ENV.key?('MERRITT_ADMIN_CONFIG') ? ENV['MERRITT_ADMIN_CONFIG'] : 'default'
        config = Uc3Ssm::ConfigResolver.new.resolve_file_values(file: config_file, resolve_key: config_block, return_key: config_block)
        config['request_id'] = context.aws_request_id

        collHandler = Handler.new(config, event, context.client_context)
        # Read the notes in LambdaBase for a description of how authentication is performed
        # A unique exception will be called if the user/client cannot authenticate
        collHandler.check_permission

        respath = event.fetch("path", "")
        $TASKNAME = respath
        return LambdaBase.redirect("/web/index.html") if respath.empty?
        return LambdaBase.redirect("/web#{respath}") if respath =~ %r[^/index.html.*]
        myparams = collHandler.get_params_from_event(event)
        path = collHandler.get_key_val(myparams, 'path', 'na')
        $TASKNAME = path unless path == 'na'
        return collHandler.web_assets("/web/favicon.ico", myparams) if respath =~ %r[^/favicon.ico.*]
        return collHandler.web_assets(respath, myparams) if collHandler.web_asset?(respath) && respath != '/web/index.html'

        dbconf = config.fetch('dbconf', {})
        client = collHandler.get_mysql

        # use database to populate page with a list of collections
        if respath == '/web/index.html'
          $mcolls = Handler.get_collection_map(client)
          return collHandler.web_assets(respath, myparams) 
        end

        LambdaBase.log_config(config, "PATH: #{respath}; PARAMS: #{myparams}")

        query_factory = QueryFactory.new(
          client, 
          config
        )
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
      rescue PermissionDeniedError => e
        log_config(config, e.message)
        return LambdaBase.error(401, e.message, false)
      rescue => e
        LambdaBase.log_config(config, e.message)
        LambdaBase.log_config(config, e.backtrace)
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

    def initialize(config, event, context)
      super(config, event, context)
    end
     
    def template_parameters(path, myparams)
      map = super(path, myparams)
      map['ARKFORM_JS'] = Mustache.render(File.open("template/arkform.js").read, map)
      map['LAMBDABASE_JS'] = Mustache.render(File.open("template/lambda.base.js").read, map)
      if path == '/web/describeReports.html'
        map['REPORTS'] = getReportsList
      #elsif path =~ %r[/web/merritt-reports/filemimelist]
      #  mnemonic = myparams.fetch("mnemonic","na")
      #  map['MNEMONIC'] = mnemonic
      #  map['JSON_FILEMIME_REPORT_DATA'] = get_report_url("merritt-reports/filemimelist/#{mnemonic}.out.json")
      #  map['JSON_FILEMIME_REPORT_DATE'] = get_report_date("merritt-reports/filemimelist/#{mnemonic}.out.json")
      elsif path == '/web/index.html' 
        map['MCOLLS'] = $mcolls
      end
      map
    end

    def self.get_collection_map(client)
      m = []
      stmt = client.prepare(%{
        select mnemonic,name from inv.inv_collections 
        where mnemonic is not null and mnemonic not like '%sla' 
        order by mnemonic
      })
      results = stmt.execute()
      results.each do |r|
        m.push({mnemonic: r.values[0], name: r.values[1]})
      end
      m
    end

    def get_report_url(key)
      s3_client = Aws::S3::Client.new(region: 'us-west-2')
      s3bucket = @config['s3-bucket']
      signer = Aws::S3::Presigner.new
      url, headers = signer.presigned_request(
        :get_object, 
        bucket: s3bucket, 
        key: key
      )
      url
    end

    def get_report_date(key)
      s3_client = Aws::S3::Client.new(region: 'us-west-2')
      s3bucket = @config['s3-bucket']
      data = s3_client.head_object(
        bucket: s3bucket, 
        key: key
      )
      return "" if data.nil?
      "Updated #{data.last_modified.getlocal.strftime('%Y-%m-%d %H:%M:%S')}"
    end

    def description_doc(rpt)
      desc = rpt.fetch('description', '')
      doc = rpt.fetch('documentation', '')
      datatypes = rpt.fetch('report-datatypes', [])

      s = desc
      s += "\n\n*Technical Documentation:*\n```\n#{doc}\n```" unless doc.empty?
      s += "\n\n_Report Data Types that Link Here:_ \n" unless datatypes.empty?
      datatypes.each do |dt|
        s += "- #{dt}\n"
      end
      s
    end

    def getReportsArr
      reports = YAML.load_file("config/reports.yml")
      rptlist = []
      reports.keys.each do |k|
        rpt = reports[k]
        rptlist.append({
          report: k,
          title: rpt.fetch('link-title', '--'), 
          breadcrumb: rpt.fetch('breadcrumb', ''), 
          class: rpt.fetch('class', 'Undefied'), 
          category: rpt.fetch('category', ''), 
          description: rpt.fetch('description', ''), 
          description_doc: description_doc(rpt),
          documentation: rpt.fetch('documentation', ''), 
          iterative: rpt.fetch('iterative', false)
        })
      end
      rptlist
    end
  
    def getReportsList
      rptlist = getReportsArr
      rptlist.sort!{
        |a,b| a[:report] <=> b[:report]  
      }
      rptlist
    end

    def getReportsMap
      rptmap = {}
      getReportsArr.each do |rpt|
        path = rpt.fetch(:path, '')
        rptmap[path] = [] unless rptmap.key?(path)
        rptmap[path].push(rpt)
      end
      maplist = []
      rptmap.keys.sort.each do |p|
        maplist.push({path: p, reports: rptmap[p]})
      end
      maplist
    end
  end

end
