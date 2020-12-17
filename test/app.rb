require 'sinatra'
require 'sinatra/base'

get '/web' do
  send_file "../web/index.html"
end

get '/web/' do
  send_file "../web/index.html"
end

get '/web/:filename' do |filename|
  send_file "../web/#{filename}"
end
