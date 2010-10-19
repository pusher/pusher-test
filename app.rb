require 'pusher'
require 'sinatra'

# On heroku these will be configured for you
if development?
  Pusher.app_id = '2531'
  Pusher.key = '22364f2f790269bec0a0'
  Pusher.secret = 'f1d153a7995462c7e28c'
end

get '/' do
  erb :index
end

# /1.2.3
get /\/(\d+.\d+.*\d*)/ do |version|
  @version = version

  erb :public
end

post '/hello' do
  Pusher['channel'].trigger('event', 'hello')
  
  return 'ok'
end

helpers do
  def link_to(name, url)
    "<a href=#{url}>#{name}</a>"
  end
end