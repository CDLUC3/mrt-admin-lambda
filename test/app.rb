require 'sinatra'
require 'sinatra/base'
require_relative '../src/lambda_function'

get '/web' do
  send_file "../web/index.html"
end

get '/web/' do
  send_file "../web/index.html"
end

get '/web/:filename' do |filename|
  send_file "../web/#{filename}"
end

get '/*' do
  path = params['splat'][0]
  event = {path: path, queryStringParameters: params}
  ENV['MERRITT_ADMIN_CONFIG'] = 'config/database.localcred.yml'
  resp = lambda_handler(event: event, context: {})
  status resp[:statusCode]
  resp[:body]
end
