require 'pusher'
require 'sinatra'
require 'version'
require 'yaml'
require 'json'

class Environment
  CONFIG = begin
    YAML.load_file(File.expand_path('../config.yml', __FILE__))
  end

  attr_reader :name

  def self.list
    CONFIG.keys
  end

  def initialize(name)
    @name = name
    env_config = CONFIG[name] || raise("Unknown config")

    # Default config
    @config = {
      app_id: '',
      key: '',
      secret: '',
      host: 'api.pusherapp.com',
      port: 80,
      ws_host: 'ws.pusherapp.com',
      ws_port: 80,
      wss_port: 443,
      sockjs_host: 'sockjs.pusher.com',
      sockjs_http_port: 80,
      sockjs_https_port: 443,
    }.merge(env_config)
  end

  def client
    @client ||= Pusher::Client.new(@config)
  end

  def [](attribute)
    @config[attribute]
  end
end

VERSIONS = %w{1.1 1.2 1.2.1 1.3 1.4 1.4.1 1.4.2 1.4.3 1.5.0 1.5.1
  1.6.0 1.6.1 1.6.2 1.6.3 1.6.4
  1.7.0 1.7.1 1.7.2 1.7.3 1.7.4 1.7.5 1.7.6
  1.8.0 1.8.1 1.8.2 1.8.3 1.8.4 1.8.5 1.8.6
  1.9.0 1.9.1 1.9.2 1.9.3 1.9.4 1.9.5 1.9.6
  1.10.1
  1.11.0 1.11.1 1.11.2
  1.12.0 1.12.1 1.12.2 1.12.3 1.12.4 1.12.5 1.12.6 1.12.7
}

get '/favicon.ico' do
  status 404
  return '404'
end

get '/' do
  @ssl, version = test_config.values_at(:ssl, :version)
  @ssl = @ssl || false
  @version = Version.new(version)
  @env = begin
    pusher_env
  rescue
    return "Unknown environment #{params[:env]}. Please add to config.yml."
  end

  @js_host = if params[:js_host]
    # You're probably developing the js and won't be serving it over ssl
    "http://#{params[:js_host]}"
  else
    @ssl ? "https://#{@env[:cdn_https_host]}" : "http://#{@env[:cdn_http_host]}"
  end

  enabled_transports = if params[:transports].is_a?(Array)
    params[:transports]
  else
    ["ws", "flash", "sockjs"]
  end
  @transports = Hash[enabled_transports.map { |t| [t, true] }]

  erb :public
end

post '/hello' do
  pusher_env.client['channel'].trigger('event', 'hello')
  cache_control "no-cache"
  return 'ok'
end

helpers do
  def pusher_env
    Environment.new(params[:env] || "default")
  end

  def link_to(name, url, options = {})
    "<a href=\"#{url}\" class=\"#{options[:class]}\">#{name}</a>"
  end

  def files(version)
    if version >= '1.12.4'
      %w{pusher.js pusher.min.js flashfallback.js flashfallback.min.js json2.js
         json2.min.js sockjs.js sockjs.min.js WebSocketMain.swf}
    elsif version >= '1.6.2'
      %w{pusher.js pusher.min.js flashfallback.js flashfallback.min.js json2.js
         json2.min.js WebSocketMain.swf}
    elsif version >= '1.2'
      %w{pusher.js pusher.min.js WebSocketMain.swf}
    else
      %w{pusher.js}
    end
  end

  def js_source(js_host, version, file)
    "#{js_host}/#{version}/#{file}"
  end

  def test_config(options = {})
    {
      env: params[:env] || 'default',
      version: params[:version] || VERSIONS.last,
      ssl: params.key?("ssl") || nil,
      js_host: params[:js_host],
      transports: params[:transports],
    }.merge(options).select { |k, v| v }
  end

  def test_query_string(options)
    "?#{Rack::Utils.build_nested_query(test_config(options))}"
  end
end
