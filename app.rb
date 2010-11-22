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

VERSIONS = %w{1.1 1.2 1.2.1 1.3 1.4 1.4.1 1.4.2 1.4.3 1.5.0 1.5.1 1.6.0 1.6.1 1.6.2 1.6.3 1.6.4 1.7.0 dev}

# /1.2.3
get /\/(\d+.\d+.*\d*)/ do |version|
  @version = version
  @ssl = params[:ssl]

  erb :public
end

get '/dev' do
  @version = 'dev'

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

  def files(version)
    case version
    when ('1.1'...'1.2')
      %w{pusher.js}
    when ('1.2'...'1.6.2')
      %w{pusher.js pusher.min.js WebSocketMain.swf}
    when ('1.6.2'...'2.0')
      %w{pusher.js pusher.min.js flashfallback.js flashfallback.min.js json2.js json2.min.js WebSocketMain.swf}
    else
      %{unknown}
    end
  end

  def host(version)
    if version == 'dev'
      'localhost:4500'
    else
      'js.pusherapp.com'
    end
  end

  def source(version, file, ssl = false)
    if ssl
      "https://d3ds63zw57jt09.cloudfront.net/#{version}/#{file}"
    else
      "http://#{host(version)}/#{version}/#{file}"
    end
  end
end