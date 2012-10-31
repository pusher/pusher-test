require 'pusher'
require 'sinatra'
require 'version'

module Pusher
  class << self
    attr_accessor :ws_host
    attr_accessor :ws_port
    attr_accessor :wss_port
    attr_accessor :sockjs_host
    attr_accessor :sockjs_http_port
    attr_accessor :sockjs_https_port
  end
end

# On heroku these will be configured for you

Pusher.app_id = '2531'
Pusher.key = '22364f2f790269bec0a0'
Pusher.secret = 'f1d153a7995462c7e28c'
if development?
  Pusher.host = 'localhost'
  Pusher.port = 8081
  Pusher.ws_host = 'localhost'
  Pusher.ws_port = 8090
  Pusher.wss_port = 9090
  Pusher.sockjs_host = 'localhost'
  Pusher.sockjs_http_port = 18080
  Pusher.sockjs_https_port = 18443
end

if File.exists?("/etc/pusher/pusher-test-config.yml")
  require "yaml"
  conf=YAML.load_file("/etc/pusher/pusher-test-config.yml")
  conf.each do |key,value|
    Pusher.send("#{key}=",value)
  end
end

get '/' do
  erb :index
end

VERSIONS = %w{1.1 1.2 1.2.1 1.3 1.4 1.4.1 1.4.2 1.4.3 1.5.0 1.5.1
  1.6.0 1.6.1 1.6.2 1.6.3 1.6.4
  1.7.0 1.7.1 1.7.2 1.7.3 1.7.4 1.7.5 1.7.6
  1.8.0 1.8.1 1.8.2 1.8.3 1.8.4 1.8.5 1.8.6
  1.9.0 1.9.1 1.9.2 1.9.3 1.9.4 1.9.5 1.9.6
  1.10.0-pre 1.10.1
  1.11.0 1.11.1 1.11.2
  1.12.0 1.12.1 1.12.2 1.12.3 1.12.4 1.12.5}

get '/favicon.ico' do
  status 404
  return '404'
end

# /1.2.3
get(/(\d+\.\d+\.\d+[-pre]*)/) do |version|
  @version = Version.new(version)
  @ssl = params[:ssl]

  erb :public
end

get '/:name' do |name|
  @version = Version.new(name)
  @ssl = params[:ssl]

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
    if version >= '1.12.4'
      %w{pusher.js pusher.min.js flashfallback.js flashfallback.min.js json2.js json2.min.js sockjs.js sockjs.min.js WebSocketMain.swf}
    elsif version >= '1.6.2'
      %w{pusher.js pusher.min.js flashfallback.js flashfallback.min.js json2.js json2.min.js WebSocketMain.swf}
    elsif version >= '1.2'
      %w{pusher.js pusher.min.js WebSocketMain.swf}
    else
      %w{pusher.js}
    end
  end

  def host(version, ssl = false)
    if version == '8.8.8'
      'localhost:5555'
    else
      ssl ? 'd3dy5gmtp8yhk7.cloudfront.net' : 'js.pusher.com'
    end
  end

  def path(version, file)
    if version == '8.8.8'
      "#{file}"
    else
      "#{version}/#{file}"
    end
  end

  def source(version, file, ssl = false)
    if version == "8.8.8"
      ssl = false
    end
    "#{ssl ? 'https' : 'http'}://#{host(version, ssl)}/#{path(version, file)}"
  end
end
