require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'sinatra/base'

require 'json'
require 'httpclient'

require "base64"
require "uri"

# ruby app.rb -o 0.0.0.0
set :port, 8091

set :bind, '0.0.0.0'

get '/web' do
  send_file "../web/index.html"
end
  
get '/web/' do
  send_file "../web/index.html"
end
  
get '/web/:filename' do |filename|
  send_file "../web/#{filename}"
end

post '/web' do
  send_file "../web/index.html"
end
  
post '/web/' do
  send_file "../web/index.html"
end
  
post '/web/:filename' do |filename|
  send_file "../web/#{filename}"
end

def lambda_process(event)
  cli = HTTPClient.new
  url = "#{ENV['LAMBDA_DOCKER_HOST']}/2015-03-31/functions/function/invocations"
  resp = cli.post(url, event)
  body = JSON.parse(resp.body)
  status body['statusCode']
  headers body['headers']
  body['body']
end

get '/lambda*' do
  path = params['splat'][0]
  path=path.gsub(/^lambda\//,'')
  # remove leading slash, if present
  path=path.gsub(/^\//,'')

  event = {
    path: path, 
    queryStringParameters: params,
    httpMethod: "GET"
  }.to_json
  lambda_process(event)
end

post '/lambda*' do
  path = params['splat'][0]
  path=path.gsub(/^lambda\//,'')
  # remove leading slash, if present
  path=path.gsub(/^\//,'')

  event = {
    path: path, 
    body: Base64.encode64(URI.encode_www_form(params)),
    httpMethod: "POST",
    isBase64Encoded: true
  }.to_json
  lambda_process(event)
end
