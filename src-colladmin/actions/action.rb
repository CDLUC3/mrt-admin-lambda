require 'cgi'
# require 'aws-sdk-s3'
require 'zip'
require 'mysql2'

class AdminAction
  def initialize(config, path, myparams)
    @config = config
    @path = path
    @myparams = myparams
    @format = 'report'
    @merritt_path = config.fetch('merritt_path','na')
  end

  def get_mysql
    raise Exception.new "The configuration yaml must contain config['dbconf']" unless @config['dbconf']
    dbconf = @config['dbconf']
    raise Exception.new "Configuration username not found" unless dbconf['username']
    db_user = dbconf['username']
    raise Exception.new "Configuration password not found" unless dbconf['password']
    db_password = dbconf['password']
    raise Exception.new "Configuration database not found" unless dbconf['database']
    db_name = dbconf['database']
    raise Exception.new "Configuration host not found" unless dbconf['host']
    db_host = dbconf['host']
    raise Exception.new "Configuration port not found" unless dbconf['port']
    db_port = dbconf['port']
  
    Mysql2::Client.new(
      :host => db_host,
      :username => db_user,
      :database=> db_name,
      :password=> db_password,
      :port => db_port)
  end
  
  def get_param(key, defval)
    @myparams.key?(key) ? CGI.unescape(@myparams[key].strip) : defval
  end

  def get_title
    "Collection Admin Query"
  end

end
