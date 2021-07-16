require 'mysql2'
require "base64"
require "cgi"
require_relative 'lambda_base'
require_relative 'queries/query'
require_relative 'queries/query_factory'

module LambdaFunctions
  class Handler
    # Handle GET or POST event structures passed in via the ALB
    def self.get_params_from_event(event)
      data = event ? event : {}
      method = data.fetch('httpMethod', 'GET')

      return data.fetch('queryStringParameters', data) if method == 'GET'

      if data['isBase64Encoded'] && data.key?('body')
        body = Base64.decode64(data['body'])
        return CGI::parse(body).transform_values(&:first)
      end
      body = data.fetch('body', '')
      return {} if body.empty?            
      CGI::parse(body).transform_values(&:first)
    end

    def self.process(event:,context:)
      begin
        config_file = 'config/database.ssm.yml'
        config_block = ENV.key?('MERRITT_ADMIN_CONFIG') ? ENV['MERRITT_ADMIN_CONFIG'] : 'default'
        @config = Uc3Ssm::ConfigResolver.new.resolve_file_values(file: config_file, resolve_key: config_block, return_key: config_block)
        dbconf = @config.fetch('dbconf', {})
        client = get_mysql(dbconf)

        myparams = get_params_from_event(event)
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
