require 'time'
require 'json'
require 'yaml'
require 'uc3-ssm'
require 'mustache'

class LambdaBase

  def initialize(config)
    @config =  config
  end

  # Handle GET or POST event structures passed in via the ALB
  def get_params_from_event(event)
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

  def get_key_val(obj, key, defval='')
    return "" unless obj
    return obj[key] if obj[key]
    return obj[key.to_sym] if obj[key.to_sym]
    defval
  end     

  def get_mysql
    dbconf = @config.fetch('dbconf', {})
    raise Exception.new "Configuration username not found" unless dbconf['username']
    raise Exception.new "Configuration password not found" unless dbconf['password']
    raise Exception.new "Configuration database not found" unless dbconf['database']
    raise Exception.new "Configuration host not found" unless dbconf['host']
    raise Exception.new "Configuration port not found" unless dbconf['port']

    Mysql2::Client.new(
      :host => dbconf['host'],
      :username => dbconf['username'],
      :database=> dbconf['database'],
      :password=> dbconf['password'],
      :port => dbconf['port'],
      :encoding => dbconf.fetch('encoding', 'utf8mb4'),
      :collation => dbconf.fetch('collation', 'utf8mb4_unicode_ci'),
    )
  end

  def content_type(ext)
    return "text/html" if ext == "html" || ext == "htm"
    return "text/javascript" if ext == "js"
    return "text/css" if ext == "css"
    nil
  end
  
  def web_asset?(path)
    puts(path)
    path =~ %r[^/web/] ? true : false
  end

  def self.admintool_url
    "#{ENV.fetch('ADMIN_ALB_URL','')}/web/index.html"
  end

  def self.colladmin_url
    "#{ENV.fetch('COLLADMIN_ALB_URL','')}/web/collIndex.html"
  end

  def self.colladmin_root_url
    "#{ENV.fetch('COLLADMIN_ALB_URL','')}"
  end

  def self.colladmin_url_admin
    "#{ENV.fetch('COLLADMIN_ALB_URL','')}/web/collAdmin.html"
  end

  def default_template_parameters
    {
      ADMINTOOL_HOME: LambdaBase.admintool_url, 
      COLLADMIN_HOME: LambdaBase.colladmin_url,
      COLLADMIN_ROOT: LambdaBase.colladmin_root_url,
      COLLADMIN_ADMIN: LambdaBase.colladmin_url_admin,
      NOW: Time.now.strftime("%Y-%m-%dT%H:%M:%S%z"),
      MYENV: LambdaBase.get_environment,
      IS_DOCKER: LambdaBase.is_docker,
      NOT_DOCKER: !LambdaBase.is_docker,
      IS_PROD: LambdaBase.is_prod,
      IS_STAGE: LambdaBase.is_stage,
    }
  end

  def template_parameters(path, myparams)
    return default_template_parameters if path == '/web/lambda.base.js'
    return default_template_parameters if path == '/web/coll-lambda.base.js'
    return default_template_parameters if path =~ %r[^/web/.*\.html]
    return {} if path == 'web/sorttable.js'
    return default_template_parameters if path =~ %r[^/web/.*\.js]
    {}
  end

  def web_assets(path, myparams)
    qpath = "/var/task#{path}"
    return LambdaBase.error(404, "File not found #{path}", false) unless File.file?(qpath)
    ext = path.split(".")[-1]
    ctype = content_type(ext)
    return LambdaBase.error(404, "Unsupported content type #{ext}", false) unless ctype
    body = File.open(qpath).read
    map = template_parameters(path, myparams)
    body = Mustache.render(body, map) unless map.empty?
    { 
      statusCode: 200, 
      headers: {
        'Content-Type' => ctype,
        'Cache-Control' => 'no-store'
      },
      body: body
    }
  end
  
  def redirect(path)
    { 
      statusCode: 303, 
      headers: {
        'Location' => path
      },
      body: "Redirect to #{path}"
    }
  end

  def self.error(status, message, return_page = false)
    if status != 200 && return_page
      { 
        statusCode: 200, 
        headers: {'Content-Type': 'text/html'},
        body: Mustache.render(File.open('template/error.html').read, message: message)
      }  
    else 
      { 
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Content-Type': 'text/plain; charset=UTF-8',
        },
        statusCode: status, 
        body: message
      }
    end
  end

  def self.get_environment
    c = ENV.fetch('MERRITT_ADMIN_CONFIG', 'default')
    return c unless c == "default"
    ENV.fetch('SSM_ROOT_PATH', '')
  end
   
  def self.is_docker
    LambdaBase.get_environment == "docker"
  end


  def self.is_prod
    LambdaBase.get_environment =~ %r[prd]
  end

  def self.is_stage
    LambdaBase.get_environment =~ %r[stg]
  end
end