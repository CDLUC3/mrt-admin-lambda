require 'sinatra'
require 'sinatra/base'
require '../src/lambda_function'


get '/*' do |path|
  puts "*** #{path}"
  event = {path: path}
  resp = lambda_handler(event: event, context: {})
  puts "*** #{resp[:body]}"
  resp[:body]
end
