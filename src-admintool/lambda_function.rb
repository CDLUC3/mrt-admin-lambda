require 'mysql2'
require "base64"
require "cgi"
require_relative 'lambda_base'
require_relative 'queries/query'
require_relative 'queries/query_factory'

module LambdaFunctions
  class Handler < LambdaBase

    def self.process(event:,context:)
      begin
        config_file = 'config/database.ssm.yml'
        config_block = ENV.key?('MERRITT_ADMIN_CONFIG') ? ENV['MERRITT_ADMIN_CONFIG'] : 'default'
        config = Uc3Ssm::ConfigResolver.new.resolve_file_values(file: config_file, resolve_key: config_block, return_key: config_block)
        collHandler = Handler.new(config, event, context.client_context)
        # Read the notes in LambdaBase for a description of how authentication is performed
        # A unique exception will be called if the user/client cannot authenticate
        collHandler.check_permission

        respath = event.fetch("path", "")
        return LambdaBase.redirect("/web/index.html") if respath.empty?
        return LambdaBase.redirect("/web#{respath}") if respath =~ %r[^/index.html.*]
        myparams = collHandler.get_params_from_event(event)
        return collHandler.web_assets("/web/favicon.ico", myparams) if respath =~ %r[^/favicon.ico.*]
        return collHandler.web_assets(respath, myparams) if collHandler.web_asset?(respath)

        dbconf = config.fetch('dbconf', {})
        client = collHandler.get_mysql

        puts(myparams)

        path = collHandler.get_key_val(myparams, 'path', 'na')
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
        puts(e.message)
        return LambdaBase.error(401, e.message, false)
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

    def initialize(config, event, context)
      super(config, event, context)
    end
     
    def template_parameters(path, myparams)
      map = super(path, myparams)
      map['ARKFORM_JS'] = Mustache.render(File.open("template/arkform.js").read, map)
      map['LAMBDABASE_JS'] = Mustache.render(File.open("template/lambda.base.js").read, map)
      if path == '/web/describeReports.html'
        map['REPORTS'] = getReportsList
      elsif path == '/web/navReports.html'
        map['REPORTSMAP'] = getReportsMap
      end
      map
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
          path: rpt.fetch('nav', {}).fetch('path', '--'), 
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
        |a,b| "#{a[:path]}/#{a[:report]}" <=> "#{b[:path]}/#{b[:report]}"  
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
