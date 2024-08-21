# frozen_string_literal: true

require_relative 'action'
require 'aws-sdk-lambda'

# Collection Admin Task class - see config/actions.yml for description
class LambdaTagAction < AdminAction
  def initialize(config, action, path, myparams)
    super
  end

  def get_title
    'Lambda Tag Action'
  end

  def table_headers
    ['Deployed Tag', 'Status']
  end

  def table_types
    ['', 'status']
  end

  def table_rows(_body)
    ver = ENV.fetch('DOCKTAG', 'na')
    stat = ver =~ /^\d+\.\d+\.\d+$/ ? 'PASS' : 'WARN'
    [
      [ver, stat]
    ]
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
