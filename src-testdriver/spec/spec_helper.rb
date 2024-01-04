# frozen_string_literal: true

require 'colorize'
require 'uc3-ssm'

RSpec.configure do |config|
  config.color = true
  config.tty = true
  config.formatter = :documentation
end

# Glogal Test Configuration
class GlobalConfig
  @@config = {}
  @@admin_reports = {}
  @@colladmin_actions = {}

  def self.load_config
    @@config = Uc3Ssm::ConfigResolver.new.resolve_file_values(file: 'config/config.yml')
    @@admin_reports = YAML.load_file('../src-admintool/config/reports.yml')
    @@colladmin_actions = YAML.load_file('../src-colladmin/config/actions.yml')
  end

  def self.config
    @@config
  end

  def self.arn(app)
    @@config.fetch(app, {}).fetch('function', '')
  end

  def self.client_context
    Base64.strict_encode64({
      # Only custom, client, and env are passed: https://github.com/aws/aws-sdk-js/issues/1388
      custom: {
        context_code: @@config.fetch('context', '')
      }
    }.to_json)
  end

  def self.report_keys
    keys = []
    @@admin_reports.each_key do |k|
      rpt = @@admin_reports[k]
      iterative = rpt.fetch('iterative', false)
      keys.append(k) unless iterative
    end
    keys
  end

  def self.report_def(k)
    @@admin_reports[k]
  end

  def self.action_keys
    keys = []
    @@colladmin_actions.each_key do |k|
      act = @@colladmin_actions[k]
      next unless act.fetch('implemented', true)

      testing = act.fetch('testing', '')
      keys.append(k) if testing == 'automated'
    end
    keys
  end

  def self.action_def(k)
    @@colladmin_actions[k]
  end
end

GlobalConfig.load_config
