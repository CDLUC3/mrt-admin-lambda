# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'sinatra/base'

require 'json'
require 'httpclient'

require 'base64'
require 'uri'

# ruby app.rb -o 0.0.0.0
set :port, 8091

set :bind, '0.0.0.0'

def lambda_process(event)
  cli = HTTPClient.new
  url = "#{ENV.fetch('LAMBDA_DOCKER_HOST', nil)}/2015-03-31/functions/function/invocations"
  resp = cli.post(url, event)
  body = JSON.parse(resp.body)
  status body['statusCode']
  headers body['headers']
  body['body']
end

def lambda_process_assets(event)
  # Prevent resource contention by inserting random delay
  sleep(6 * rand)
  lambda_process(event)
end

get '/lambda*' do
  path = params['splat'][0]
  path = path.gsub(%r{^lambda/}, '')
  # remove leading slash, if present
  path = path.gsub(%r{^/}, '')

  event = {
    path: path,
    queryStringParameters: params,
    httpMethod: 'GET'
  }.to_json
  lambda_process(event)
end

get '/web/*' do
  path = params['splat'][0]

  event = {
    path: "/web/#{path}",
    queryStringParameters: params,
    httpMethod: 'GET'
  }.to_json
  lambda_process_assets(event)
end

post '/lambda*' do
  path = params['splat'][0]
  path = path.gsub(%r{^lambda/}, '')
  # remove leading slash, if present
  path = path.gsub(%r{^/}, '')

  event = {
    path: path,
    body: Base64.encode64(URI.encode_www_form(params)),
    httpMethod: 'POST',
    isBase64Encoded: true
  }.to_json
  lambda_process(event)
end

post '/web/*' do
  path = params['splat'][0]
  path = path.gsub(%r{^lambda/}, '')
  # remove leading slash, if present
  path = path.gsub(%r{^/}, '')

  event = {
    path: path,
    body: Base64.encode64(URI.encode_www_form(params)),
    httpMethod: 'POST',
    isBase64Encoded: true
  }.to_json
  lambda_process(event)
end
