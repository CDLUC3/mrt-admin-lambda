require 'json'

def format(obj, key)
  return "" unless obj
  return "" unless obj[key]
  obj[key].to_json
done

def lambda_handler(event:, context:)
    # TODO implement
    {
      statusCode: 200,
      body: {
        path: format(event, 'path')
      }
    }
    #JSON.generate('Hello from Lambda!')
end
