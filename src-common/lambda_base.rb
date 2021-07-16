require 'json'
require 'yaml'
require 'uc3-ssm'

class LambdaBase
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
end