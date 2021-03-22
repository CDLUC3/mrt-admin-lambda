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

  def get_param(key, defval)
    @myparams.key?(key) ? CGI.unescape(@myparams[key].strip) : defval
  end

  def get_title
    "Collection Admin Query"
  end

end
