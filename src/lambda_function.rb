require 'json'
#equire 'aws-sdk-ssm'
#require 'aws-sdk-lambda'
require 'mysql2'

def format(obj, key)
  return "" unless obj
  return "" unless obj[key]
  obj[key]
end

def getSsmPath(arn)
  lambda = Aws::Lambda::Client.new
  #lambda.list_tags({resource: arn})
  '/uc3/mrt/stg/'
end

def getSsmVal(ssm, root, path)
  ssm.get_parameter(name: "#{root}#{path}")[:parameter][:value]
end

def lambda_handler(event:, context:)
  {
    statusCode: 200,
    body: {
      path: 1
    }.to_json
  }
end

def lambda_handler2(event:, context:)
    arn = context.invoked_function_arn
    ssmpath = getSsmPath(arn)
    ssm = Aws::SSM::Client.new
    db_user = getSsmVal(ssm, ssmpath, 'billing/readonly/db-user')
    db_password = getSsmVal(ssm, ssmpath, 'billing/readonly/db-password')
    db_name = getSsmVal(ssm, ssmpath, 'billing/db-name')
    db_host = getSsmVal(ssm, ssmpath, 'billing/db-host')

    client = Mysql2::Client.new(
      :host => db_host,
      :username => db_user,
      :database=> db_name,
      :password=> db_password,
      :port => 3306)
    sql = "SELECT id, name FROM inv.inv_collections"

    if event['path'] == '/owners'
      sql = "SELECT id, name FROM inv.inv_owners"
    end
    params = []
    results = client.query(sql)
    data = []
    results.each do |r|
      rdata = []
      rdata.push(r['id'])
      rdata.push(r['name'])
      data.push(rdata)
    end

    {
      statusCode: 200,
      body: {
        path: format(event, 'path'),
        params: format(event, 'queryStringParameters'),
        arn: arn,
        tags: ssmpath,
        db_res: data
      }.to_json
    }
    #JSON.generate('Hello from Lambda!')
end