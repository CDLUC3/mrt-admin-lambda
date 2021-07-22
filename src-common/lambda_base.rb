require 'json'
require 'yaml'
require 'uc3-ssm'
require 'mustache'

class LambdaBase
  # Handle GET or POST event structures passed in via the ALB
  def self.get_params_from_event(event)
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

  def self.get_key_val(obj, key, defval='')
    return "" unless obj
    return obj[key] if obj[key]
    return obj[key.to_sym] if obj[key.to_sym]
    defval
  end     

  def self.get_mysql(dbconf)
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

  def self.content_type(ext)
    return "text/html" if ext == "html" || ext == "htm"
    return "text/javascript" if ext == "js"
    return "text/css" if ext == "css"
    nil
  end
  
  def self.web_asset?(path)
    puts(path)
    path =~ %r[^/web/] ? true : false
  end

  def self.template_parameters(path)
    lmap = {
      ADMINTOOL_HOME: "#{ENV.fetch('ADMIN_ALB_URL','')}/web/index.html", 
      COLLADMIN_HOME: "#{ENV.fetch('COLLADMIN_ALB_URL','')}/web/collIndex.html"
    }
    return lmap if path == '/web/lambda.base.js'
    return lmap if path == '/web/coll-lambda.base.js'
    return lmap if path == '/web/index.html'
    {}
  end

  def self.web_assets(path)
    qpath = "/var/task#{path}"
    return error(404, "File not found #{path}", false) unless File.file?(qpath)
    ext = path.split(".")[-1]
    ctype = content_type(ext)
    return error(404, "Unsupported content type #{ext}", false) unless ctype
    body = File.open(qpath).read
    map = LambdaBase.template_parameters(path)
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
  
  def self.error(status, message, return_page = false)
    if status != 200 && return_page
      { 
        statusCode: 200, 
        headers: {'Content-Type' => 'text/html'},
        body: Mustache.render(File.open('template/error.html').read, message: message)
      }  
    else
      { 
        statusCode: status, 
        headers: {'Content-Type' => 'text'},
        body: message 
      }
    end
  end
end