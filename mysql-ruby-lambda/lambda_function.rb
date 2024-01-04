# frozen_string_literal: true

require 'json'
require 'uc3-ssm'
require 'mysql2'

module LambdaFunctions
  # Placeholder entrypoint for a lambda base image built with mysql.
  # The build for this image is complicated because mysql requires a binary compile.
  class Handler
    def self.process(event:)
      json = {
        message: 'This is a placeholder for your lambda code',
        event: event
      }
      {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Content-Type': 'application/json; charset=utf-8'
        },
        statusCode: 200,
        body: json.to_json
      }
    rescue StandardError => e
      {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Content-Type': 'application/json; charset=utf-8'
        },
        statusCode: 500,
        body: { error: e.message }.to_json
      }
    end
  end
end
