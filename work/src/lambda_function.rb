require 'json'

def lambda_handler(event:, context:)
    # TODO implement
    { statusCode: 200, body: event.to_json }
    #JSON.generate('Hello from Lambda!')
end
