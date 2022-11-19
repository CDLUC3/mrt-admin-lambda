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
        reports = YAML.load_file("config/reports.yml")
        map['REPORTS'] = []
        reports.keys.each do |k|
          rpt = reports[k]
          map['REPORTS'].append({
            report: k,
            title: rpt.fetch('link-title', '--'), 
            path: rpt.fetch('nav', {}).fetch('path', '--'), 
            class: rpt.fetch('class', 'Undefied'), 
            category: rpt.fetch('category', ''), 
            description: rpt.fetch('description', ''), 
            iterative: rpt.fetch('iterative', false)
          })
        end
        map['REPORTS'].sort!{
          |a,b| "#{a[:path]}/#{a[:report]}" <=> "#{b[:path]}/#{b[:report]}"  
        }
      end
      map
    end
  end

end
