require 'mysql2'
require "base64"
require "cgi"
require_relative 'lambda_base'
require_relative 'queries/query'
require_relative 'queries/query_factory'

module LambdaFunctions
  class Handler

    def self.process(event:,context:)
      begin
        respath = event.fetch("path", "")
        return LambdaBase.web_assets(respath) if LambdaBase.web_asset?(respath)

        config_file = 'config/database.ssm.yml'
        config_block = ENV.key?('MERRITT_ADMIN_CONFIG') ? ENV['MERRITT_ADMIN_CONFIG'] : 'default'
        @config = Uc3Ssm::ConfigResolver.new.resolve_file_values(file: config_file, resolve_key: config_block, return_key: config_block)
        dbconf = @config.fetch('dbconf', {})
        client = LambdaBase.get_mysql(dbconf)

        myparams = LambdaBase.get_params_from_event(event)
        puts(myparams)

        path = LambdaBase.get_key_val(myparams, 'path', 'na')
        query_factory = QueryFactory.new(
          client, 
          @config
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
  end
end
