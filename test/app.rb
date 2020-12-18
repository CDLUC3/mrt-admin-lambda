require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'sinatra/base'
require 'sinatra/cross_origin'

require 'json'

# ruby app.rb -o 0.0.0.0
set :port, 8091

set :bind, '0.0.0.0'
configure do
  enable :cross_origin
end

before do
  headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
  headers['Access-Control-Allow-Origin'] = '*'
  headers['Access-Control-Allow-Headers'] = 'accept, authorization, origin, Content-Type'
end

get '/web' do
  send_file "../web/index.html"
end

get '/web/' do
  send_file "../web/index.html"
end

get '/web/:filename' do |filename|
  send_file "../web/#{filename}"
end
