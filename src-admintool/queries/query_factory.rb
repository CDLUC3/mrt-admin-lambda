# frozen_string_literal: true

# Explicitly include all parent classes
require_relative 'query'
require_relative 's3_query'
require_relative 'objects_query'
require_relative 'files_query'
require_relative 'idlist_query'
require_relative 'idlist_compare_query'
require 'yaml'

# Include all Query classes
Dir["#{File.dirname(__FILE__)}/*query.rb"].sort.each { |file| require file }

class QueryFactory
  def initialize(client, config)
    @client = client
    @config = config
    @reports = YAML.load_file('config/reports.yml')
  end

  attr_reader :client, :config

  def get_report_def(path)
    @reports.fetch(path, { class: AdminQuery, description: 'Report not found' })
  end

  def get_query_for_path(path, myparams)
    report = get_report_def(path)
    params = report.fetch('params', [])

    # Use Ruby metaprogramming to construct the report class
    if params.length == 2
      Object.const_get(report['class']).new(self, path, myparams, params[0], params[1])
    elsif params.length == 1
      Object.const_get(report['class']).new(self, path, myparams, params[0])
    else
      Object.const_get(report['class']).new(self, path, myparams)
    end
  end
end
