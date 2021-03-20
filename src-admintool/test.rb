# Sample test program
# docker build -t x .
# docker run --rm -it --entrypoint 'bundle' -e SSM_ROOT_PATH=... x exec ruby test.rb

require 'json'
require 'yaml'
require 'uc3-ssm'
require 'mysql2'

config_file = 'config/database.ssm.yml'
@config = Uc3Ssm::ConfigResolver.new.resolve_file_values(file: config_file, resolve_key: 'default', return_key: 'default')
dbconf = @config.fetch('dbconf', {})

cli = Mysql2::Client.new(
    :host => dbconf['host'],
    :username => dbconf['username'],
    :database=> dbconf['database'],
    :password=> dbconf['password'],
    :port => dbconf['port'],
    :encoding => dbconf.fetch('encoding', 'utf8mb4'),
    :collation => dbconf.fetch('collation', 'utf8mb4_unicode_ci')
)
stmt = cli.prepare("select erc_what from inv.inv_objects where id=3057139;")
stmt.execute().each do |r|
  puts(r.fetch('erc_what', ''))
end
