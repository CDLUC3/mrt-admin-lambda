require 'json'

def format(obj, key)
  return "" unless obj
  return "" unless obj[key]
  obj[key].to_json
end

def lambda_handler(event:, context:)
    # TODO implement
    {
      statusCode: 200,
      body: {
        path: event['path']
      }
    }
    #JSON.generate('Hello from Lambda!')
end
