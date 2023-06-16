require 'json'
require 'uc3-ssm'
require 'mysql2'
 
module LambdaFunctions
  class Handler
    def self.process(event:,context:)
      begin
        json = {
          message: 'This is a placeholder for your lambda code',
          event: event
        }
        {
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json; charset=utf-8'
          },
          statusCode: 200,
          body: json.to_json
        }
      rescue => e
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
