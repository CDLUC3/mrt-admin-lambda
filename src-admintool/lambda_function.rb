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
        collHandler = Handler.new(config)
        respath = event.fetch("path", "")
        return collHandler.redirect("/web#{respath}") if respath =~ %r[^/index.html.*]
        myparams = collHandler.get_params_from_event(event)
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

    def initialize(config)
      super(config)
    end
     
    #def template_parameters(path, myparams)
    #  map = super(path, myparams)
    #  # Add app specific overrides here
    #  map
    #end
  end

end
