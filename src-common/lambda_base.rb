# frozen_string_literal: true

# Docs say that the LambdaLayer gems are found mounted as /opt/ruby/gems but an inspection
# of the $LOAD_PATH shows that only /opt/ruby/lib is available. So we add what we want here
# and indicate exactly which folders contain the *.rb files
my_gem_path = Dir['/var/task/vendor/bundle/ruby/**/bundler/gems/**/lib/']
$LOAD_PATH.unshift(*my_gem_path)

require 'time'
require 'json'
require 'yaml'
require 'uc3-ssm'
require 'mustache'
require 'base64'
require 'jwt'

# Cognito denied permission for the lambda
class PermissionDeniedError < StandardError
end

# Web clients of the Lambdas derived from this class must authenticate with Cognito.
# (This is enforced through an ALB configuration).
# Derived classes should call check_permission to trigger the authentication check.
# An exception is thrown if authentication is unsuccessful.
#
#
# WEB CLIENTS
# - The configuration value "cognito-groups-allowed" provides a list of Cognito groups
#   that may access the application (populated from SSM).
#   - If this value is set to NA, then no authentication check is performed.
#   - If this value is set, the user must belong to at least one group in this list.
#
# SERVER CLIENTS (calling aws lambda invoke)
# Server clients of this Lambda must send a client_context with the Lambda invoke.
#   They do not authenticate through Cognito.
# - The configuration value "context" contains the string that must be provided within
#   the client context (populated from SSM).
# - The Lambda client_context is parsed for a "custom" value named "context_code".
#   This value is compared with the context in the configuration.
#
# See https://github.com/CDLUC3/mrt-cron for a sample client app.
class LambdaBase
  def initialize(config, event = {}, client_context = {})
    @config = config
    @groups_allowed = @config.fetch('cognito-groups-allowed', '')
    @cognito_username = ''
    @cognito_groups = []
    @context_valid = false
    @client_context = client_context
    read_cognito_token(event)
  end

  def read_cognito_token(event)
    cognito_token = event.fetch('headers', {}).fetch('x-amzn-oidc-accesstoken', '')
    if cognito_token.empty?
      read_context
      return
    end
    begin
      jtoken = JWT.decode(cognito_token, nil, false, { algorithm: 'RS256' })
      @cognito_username = jtoken[0].fetch('username', '')
      @cognito_groups = jtoken[0].fetch('cognito:groups', [])
    rescue StandardError => e
      LambdaBase.log_config(config, e)
    end
  end

  def read_context
    return if @client_context.nil?

    code = @client_context.fetch('custom', {}).fetch('context_code', '')
    return if code.empty?
    return unless code == @config.fetch('context', '')

    @context_valid = true
  end

  def check_permission
    return if @context_valid

    return if @groups_allowed == 'NA'
    return if has_permission

    raise PermissionDeniedError,
      "User #{@cognito_username} is not allowed to access this app.  Contact the Merritt Team."
  end

  # Now permissions are enforced by the ALB/SSO
  # This is a legacy implementation that allowed Merritt to manager specific user access
  def has_permission
    @cognito_groups.each do |group|
      @groups_allowed.split(',').each do |g|
        return true if g == group
      end
    end
    false
  end

  # Handle GET or POST event structures passed in via the ALB
  def get_params_from_event(event)
    data = event || {}
    method = data.fetch('httpMethod', 'GET')

    return data.fetch('queryStringParameters', data) if method == 'GET'

    if data['isBase64Encoded'] && data.key?('body')
      body = Base64.decode64(data['body'])
      return CGI.parse(body).transform_values(&:first)
    end
    body = data.fetch('body', '')
    return {} if body.empty?

    CGI.parse(body).transform_values(&:first)
  end

  def get_key_val(obj, key, defval = '')
    return '' unless obj
    return obj[key] if obj[key]
    return obj[key.to_sym] if obj[key.to_sym]

    defval
  end

  def get_mysql
    dbconf = @config.fetch('dbconf', {})
    raise StandardError, 'Configuration username not found' unless dbconf['username']
    raise StandardError, 'Configuration password not found' unless dbconf['password']
    raise StandardError, 'Configuration database not found' unless dbconf['database']
    raise StandardError, 'Configuration host not found' unless dbconf['host']
    raise StandardError, 'Configuration port not found' unless dbconf['port']

    Mysql2::Client.new(
      host: dbconf['host'],
      username: dbconf['username'],
      database: dbconf['database'],
      password: dbconf['password'],
      port: dbconf['port'],
      encoding: dbconf.fetch('encoding', 'utf8mb4'),
      collation: dbconf.fetch('collation', 'utf8mb4_unicode_ci')
    )
  end

  def content_type(ext)
    return 'image/x-icon' if ext == 'ico'
    return 'image/jpeg' if ext == 'jpg'
    return 'text/html' if %w[html htm].include?(ext)
    return 'text/javascript' if ext == 'js'
    return 'text/css' if ext == 'css'
    return 'text/plain; charset=utf-8' if ext == 'txt'

    nil
  end

  def web_asset?(path)
    path =~ %r{^/web/} ? true : false
  end

  def self.admintool_base
    ENV.fetch('ADMIN_ALB_URL', '')
  end

  def self.ecs_admintool_url
    "#{ENV.fetch('ECS_URL', '')}"
  end

  def self.admintool_url
    "#{ENV.fetch('ADMIN_ALB_URL', '')}/web/index.html"
  end

  def self.colladmin_url
    "#{ENV.fetch('COLLADMIN_ALB_URL', '')}/web/collIndex.html"
  end

  def self.colladmin_root_url
    ENV.fetch('COLLADMIN_ALB_URL', '').to_s
  end

  def self.colladmin_url_admin
    "#{ENV.fetch('COLLADMIN_ALB_URL', '')}/web/collAdmin.html"
  end

  def default_template_parameters
    recent = ''
    begin
      secs = Time.now - File.mtime('/etc/timezone')
      recent = 'min3' if secs < 240
      recent = 'min1' if secs < 120
    rescue StandardError
      # no action taken here
    end
    vt = ENV.fetch('COMMITDATE', 'devserver')
    vt = File.mtime('/etc/timezone').strftime('%Y-%m-%dT%H:%M:%S') if vt == 'devserver'
    {
      UC3INV_HOME: @config.fetch('uc3inv_home', ''),
      ADMINTOOL_BASE: LambdaBase.admintool_base,
      ADMINTOOL_HOME: LambdaBase.admintool_url,
      ECS_URL: LambdaBase.ecs_admintool_url,
      COLLADMIN_HOME: LambdaBase.colladmin_url,
      COLLADMIN_ROOT: LambdaBase.colladmin_root_url,
      COLLADMIN_ADMIN: LambdaBase.colladmin_url_admin,
      NOW: Time.now.strftime('%Y-%m-%dT%H:%M:%S%z'),
      VERTIME: vt,
      DOCKTAG: ENV.fetch('DOCKTAG', 'na'),
      RECENT: recent,
      MYENV: LambdaBase.get_environment,
      IS_DOCKER: LambdaBase.is_docker,
      NOT_DOCKER: !LambdaBase.is_docker,
      IS_PROD: LambdaBase.is_prod,
      IS_STAGE: LambdaBase.is_stage,
      USERNAME: @cognito_username,
      GROUPS: @cognito_groups.join(','),
      HASPERM: has_permission
    }
  end

  def template_parameters(path, _myparams)
    if path =~ %r{^/web/.*\.html}
      map = default_template_parameters
      map['BUTTONS'] = File.read('template/buttons.template')
      map['ADMINNAVDATA'] = Mustache.render(File.read('template/adminnavdata.html'), map)
      map['ADMINNAV'] = Mustache.render(File.read('template/adminnav.html'), map)
      map['APITABLE_CSS'] = Mustache.render(File.read('template/api-table.css'), map)
      map['APITABLE_JS'] = Mustache.render(File.read('template/api-table.js'), map)
      map['NAVMENU_CSS'] = Mustache.render(File.read('template/navmenu.css'), map)
      map['NAVMENU'] = Mustache.render(File.read('template/navmenu.html'), map)
      map['DRAWDOWN_JS'] = Mustache.render(File.read('template/drawdown.js'), map)
      return map
    end
    return {} if path == 'web/sorttable.js'
    return default_template_parameters if path =~ %r{^/web/.*\.js}

    {}
  end

  def web_assets(path, myparams)
    qpath = "/var/task#{path}"
    return LambdaBase.error(404, "File not found #{path}", false) unless File.file?(qpath)

    ext = path.split('.')[-1]
    ctype = content_type(ext)
    return LambdaBase.error(404, "Unsupported content type #{ext}", false) unless ctype

    $TASKNAME = 'assets'
    LambdaBase.log("web asset: #{path}")
    if ctype =~ /^image.*/
      return {
        statusCode: 200,
        headers: {
          'Content-Type' => ctype
        },
        isBase64Encoded: true,
        body: Base64.strict_encode64(File.binread(qpath))
      }
    elsif ctype =~ /txt/
      ctype = 'text/plain'
    end

    body = File.read(qpath)
    map = template_parameters(path, myparams)
    body = Mustache.render(body, map) unless map.empty?
    headers = {
      'Content-Type' => ctype
    }

    headers['Cache-Control'] = 'no-store' unless path =~ %r{^/web/(favicon.ico|sorttable.js).*}
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

  def self.error(status, message, return_page)
    if status != 200 && return_page
      {
        statusCode: 200,
        headers: { 'Content-Type': 'text/html' },
        body: Mustache.render(File.read('template/error.html'), message: message)
      }
    else
      {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Content-Type': 'text/plain; charset=UTF-8'
        },
        statusCode: status,
        body: message
      }
    end
  end

  def self.ssm_root_path
    ENV.fetch('SSM_ROOT_PATH', 'na')
  end

  def self.get_environment
    c = ENV.fetch('MERRITT_ADMIN_CONFIG', 'default')
    return c unless c == 'default'

    ENV.fetch('SSM_ROOT_PATH', '')
  end

  def self.ssm_path_node(pos)
    arr = ENV.fetch('SSM_ROOT_PATH', '').split('/')
    return '' unless pos < arr.length

    arr[pos]
  end

  def self.tag_environment
    ssm_path_node(3)
  end

  def self.tag_program
    ssm_path_node(1)
  end

  def self.tag_service
    ssm_path_node(2)
  end

  def self.is_docker
    LambdaBase.get_environment == 'docker'
  end

  def self.is_prod
    LambdaBase.get_environment =~ /prd/
  end

  def self.is_stage
    LambdaBase.get_environment =~ /stg/
  end

  def self.log_config(config, message)
    puts "RequestId: #{config.fetch('request_id', $REQID)}; task: #{$TASKNAME}; #{message.to_s.gsub(/\s+/, ' ')}"
  end

  def self.log(message)
    log_config({}, message)
  end
end

# exception message strings were including a dump of object properties
# this was leaking data to opersearch.
# this prevents any object (including MySql2::Client) from dumping properties
class Object
  def inspect
    "#{self.class} (property listing suppressed)"
  end
end
