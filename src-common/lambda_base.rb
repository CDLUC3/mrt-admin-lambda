require 'time'
require 'json'
require 'yaml'
require 'uc3-ssm'
require 'mustache'
require 'base64'
require 'jwt'

class PermissionDeniedError < StandardError
  def initialize(msg)
    super(msg)
  end
end

# Web clients of the Lambdas derived from this class must authenticate with Cognito. (This is enforced through an ALB configuration).
# Derived classes should call check_permission to trigger the authentication check.  An exception is thrown if authentication is unsuccessful.
#
# WEB CLIENTS
# - The configuration value "cognito-groups-allowed" provides a list of Cognito groups that may access the application (populated from SSM).
#   - If this value is set to NA, then no authentication check is performed.
#   - If this value is set, the user must belong to at least one group in this list.
#
# SERVER CLIENTS (calling aws lambda invoke)
# Server clients of this Lambda must send a client_context with the Lambda invoke. They do not authenticate through Cognito.
# - The configuration value "context" contains the string that must be provided within the client context (populated from SSM).
# - The Lambda client_context is parsed for a "custom" value named "context_code".  This value is compared with the context in the configuration.
#
# See https://github.com/CDLUC3/mrt-cron for a sample client app.
class LambdaBase

  def initialize(config, event = {}, client_context = {})
    @config =  config
    @groups_allowed = @config.fetch("cognito-groups-allowed", "")
    @cognito_username = ""
    @cognito_groups = []
    @context_valid = false
    @client_context = client_context
    read_cognito_token(event)
  end
  
  def read_cognito_token(event)
    cognito_token = event.fetch('headers',{}).fetch('x-amzn-oidc-accesstoken','')
    if cognito_token.empty?
      read_context
      return
    end
    begin
      jtoken = JWT::decode(cognito_token, nil, false, { :algorithm => 'RS256' })
      @cognito_username = jtoken[0].fetch('username', '')
      @cognito_groups = jtoken[0].fetch("cognito:groups", [])
    rescue => e 
      puts e
    end
  end

  def read_context
    return if @client_context.nil?
    code = @client_context.fetch("custom", {}).fetch("context_code", "")
    return if code.empty?
    return unless code == @config.fetch("context", "")
    puts "Authenticated through client context"
    @context_valid = true
  end

  def check_permission
    return if @context_valid
    puts "Check: #{@cognito_username}: #{@cognito_groups.join(',')}"
    unless @groups_allowed == "NA"
      raise PermissionDeniedError.new "User #{@cognito_username} is not allowed to access this app.  Contact the Merritt Team." unless has_permission
    end
  end

  def has_permission
    @cognito_groups.each do |group|
      @groups_allowed.split(",").each do |g|
        return true if g == group
      end
    end
    false
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
    return "image/x-icon" if ext == "ico"
    return "image/jpeg" if ext == "jpg"
    return "text/html" if ext == "html" || ext == "htm"
    return "text/javascript" if ext == "js"
    return "text/css" if ext == "css"
    return "text/plain; charset=utf-8" if ext == "txt"
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
      USERNAME: @cognito_username,
      GROUPS: @cognito_groups.join(","),
      HASPERM: has_permission
    }
  end

  def template_parameters(path, myparams)
    return default_template_parameters if path == '/web/lambda.base.js'
    return default_template_parameters if path == '/web/coll-lambda.base.js'
    if path =~ %r[^/web/.*\.html]
      p = default_template_parameters
      p['BUTTONS'] = File.open("template/buttons.template").read
      p['ADMINNAV'] = Mustache.render(File.open("template/adminnav.template").read, p)
      p['COLLADMINNAV'] = Mustache.render(File.open("template/colladminnav.template").read, p)
      return p
    end
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
    if ctype =~ %r[^image.*] 
      return {
        statusCode: 200,
        headers: {
          'Content-Type' => ctype
        },
        isBase64Encoded: true,
        body: Base64.strict_encode64(IO.binread(qpath))
      }
    end

    body = File.open(qpath).read
    map = template_parameters(path, myparams)
    body = Mustache.render(body, map) unless map.empty?
    headers = {
      'Content-Type' => ctype
    }

    headers['Cache-Control'] = 'no-store' unless path =~ %r[^/web/(favicon.ico|sortable.js).*]
    { 
      statusCode: 200, 
      headers: headers,
      body: body
    }
  end
  
  def self.redirect(path)
    { 
      statusCode: 303, 
      headers: {
        'Location' => path
      },
      body: "Redirect to #{path}"
    }
  end

  def self.jsredirect(path)
    { 
      redirect_location: path
    }.to_json
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