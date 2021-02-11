require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'sinatra/base'

require 'json'
require 'httpclient'

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
  event = {path: path, queryStringParameters: params}.to_json
  puts("get")
  puts(path)
  puts(event)
  lambda_process(event)
end

post '/lambda*' do
  path = params['splat'][0]
  path=path.gsub(/^lambda\//,'')
  event = {path: path, queryStringParameters: params}.to_json
  puts("post")
  puts(path)
  puts(event)
  puts(111)
  lambda_process(event)
end
