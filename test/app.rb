require 'sinatra'
require 'sinatra/base'
require '../src/lambda_function'

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
  resp = lambda_handler(event: event, context: {})
  status resp[:status]
  resp[:body]
end
