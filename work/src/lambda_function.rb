require 'json'
require 'aws-sdk-ssm'
require 'aws-sdk-lambda'

def format(obj, key)
  return "" unless obj
  return "" unless obj[key]
  obj[key]
end

def getSsmPath(arn)
  #lambda = Aws::Lambda::Client.new
  #lambda.list_tags({resource: arn})
  '/uc3/mrt/stg/'
end

def getSsmVal(ssm, root, path)
  ssm.get_parameter(name: "#{root}#{path}")
end

def lambda_handler(event:, context:)
    arn = context.invoked_function_arn
    ssm = Aws::SSM::Client.new
    ssmpath = getSsmPath(arn)

    # TODO implement
    {
      statusCode: 200,
      body: {
        path: format(event, 'path'),
        params: format(event, 'queryStringParameters'),
        arn: arn,
        tags: ssmpath,
        db_user: getSsmVal(ssm, root, 'billing/readonly/db_user')
      }.to_json
    }
    #JSON.generate('Hello from Lambda!')
end
