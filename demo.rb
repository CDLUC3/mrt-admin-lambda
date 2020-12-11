require 'json'
def lambda_handler(event:, context:)
    {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'content-type':'application/json; charset=utf-8'
        },
        statusCode: 200,
        body: { text: 'my message' }.to_json
      }
  end