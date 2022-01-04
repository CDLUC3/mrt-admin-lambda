require 'colorize'
require 'uc3-ssm'

RSpec.configure do |config|
  config.color = true
  config.tty = true
  config.formatter = :documentation
end

class GlobalConfig
  def self.load_config
    @@config = Uc3Ssm::ConfigResolver.new.resolve_file_values({
      file: "config/config.yml"
    })
    @@admin_reports = YAML.load_file('../src-admintool/config/reports.yml')
    puts @@admin_reports
    @@colladmin_actions = YAML.load_file('../src-colladmin/config/actions.yml')
    puts @@colladmin_actions
  end

  def self.config
    @@config
  end
end

GlobalConfig.load_config