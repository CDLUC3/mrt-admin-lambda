# frozen_string_literal: true

require 'json'

input = ARGV[0] || 'filebeat.ndjson'
json = JSON.parse(File.foreach(input).first)
fields = json.fetch('attributes', {}).fetch('fields', {})
json = JSON.parse(fields)
puts JSON.pretty_generate(json)
