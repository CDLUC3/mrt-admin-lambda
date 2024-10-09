# frozen_string_literal: true

require_relative 'action'
require 'aws-sdk-lambda'
require 'csv'

# Collection Admin Task class - see config/actions.yml for description
class SystemStateAction < AdminAction
  def initialize(config, action, path, myparams)
    super
    key = 'system-state/ldap_cert_dates.csv'
    @tests = {}
    begin
      resp = @s3_client.get_object({
        bucket: @s3bucket,
        key: key
      })
      CSV.parse(resp.body.read).each do |row|
        @tests[row[0]] = DateTime.parse(row[1]).to_time
      end
    rescue StandardError
      LambdaBase.log_config(@config, "#{key} does not exist")
    end
  end

  def get_title
    'System State Task'
  end

  def table_headers
    %w[Server Date Days Status]
  end

  def table_types
    %w[name time data status]
  end

  def table_rows(_body)
    data = []
    @tests.each do |k, v|
      diff = (v - Time.now) / (24 * 3600)
      state = 'PASS'
      if diff < 15
        state = 'FAIL'
      elsif diff < 30
        state = 'WARN'
      end
      data.push([k, v, diff, state])
    end
    data
  end

  def perform_action
    convert_json_to_table({}.to_json)
  end

  def has_table
    true
  end

  def init_status
    :PASS
  end
end
