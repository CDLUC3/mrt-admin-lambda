# frozen_string_literal: true

# Sample test program
# docker build -t x .
# docker run --rm -it --entrypoint 'bundle' -e SSM_ROOT_PATH=... x exec ruby test.rb

# Docs say that the LambdaLayer gems are found mounted as /opt/ruby/gems but an inspection
# of the $LOAD_PATH shows that only /opt/ruby/lib is available. So we add what we want here
# and indicate exactly which folders contain the *.rb files
my_gem_path = Dir['/var/task/vendor/bundle/ruby/3.2.0/bundler/gems/**/lib/']
$LOAD_PATH.unshift(*my_gem_path)

require 'json'
require 'yaml'
require 'uc3-ssm'
require 'mysql2'
require_relative 'lambda_base'

config_file = 'config/database.ssm.yml'
@config = Uc3Ssm::ConfigResolver.new.resolve_file_values(file: config_file, resolve_key: 'default',
  return_key: 'default')
@config.fetch('dbconf', {})

cli = LambdaBase.new(@config).get_mysql
stmt = cli.prepare('select erc_what from inv.inv_objects limit 5;')
stmt.execute.each do |r|
  puts(r.fetch('erc_what', ''))
end
