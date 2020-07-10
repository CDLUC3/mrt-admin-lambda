require 'json'

def format(obj, key)
  return "" unless obj
  return "" unless obj[key]
  obj[key]
end

def lambda_handler(event:, context:)
    # TODO implement
    {
      statusCode: 200,
      body: {
        path: format(event, 'path'),
        params: format(event, 'queryStringParameters'),
        arn: context.invoked_function_arn
      }.to_json
    }
    #JSON.generate('Hello from Lambda!')
end
