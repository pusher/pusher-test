require 'pusher'
require 'sinatra'
require 'version'
require 'yaml'
require 'json'

def symbolize(obj)
  case obj
  when Hash
    obj.inject({}) { |mem, (k,v)| mem[k.to_sym] = symbolize(v); mem }
  else
    obj
  end
end

class Environment
  CONFIG = begin
    if ENV["CONFIG_JSON"]
      symbolize JSON.parse(ENV["CONFIG_JSON"])
    else
      symbolize YAML.load_file(File.expand_path('../config.yml', __FILE__))
    end
  rescue => e
    puts "Config required in a CONFIG_JSON env variable or ./config.yml (see .example)"
    raise e
  end

  attr_reader :name

  def self.list
    CONFIG.keys
  end

  def self.list_public
    public_clusters = [:mt1, :ap1, :eu]
    CONFIG.keys.select { |k| public_clusters.include?(k) }
  end

  def initialize(name)
    @name = name
    env_config = CONFIG[name.to_sym] || raise("Unknown config")

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
      cdn_http_host: 'js.pusher.com',
      cdn_https_host: 'js.pusher.com',
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
  2.0.0 2.0.1 2.0.2 2.0.3 2.0.4 2.0.5 2.0.6 2.0.7 2.0.8 2.0.9 2.0.10 2.0.11
  2.1.0 2.1.1 2.1.2 2.1.3 2.1.4 2.1.5 2.1.6
  2.2.0 2.2.1 2.2.2 2.2.3 2.2.4
  3.0.0 3.1.0 3.2.0
}

get '/favicon.ico' do
  status 404
  return '404'
end

get '/' do
  @ssl, version = test_config.values_at(:ssl, :version)
  if request.secure?
    @force_ssl = true
    @ssl = true
  else
    @ssl = @ssl || false
  end

  @version = Version.new(version)
  @env = begin
    pusher_env
  rescue
    return "Unknown environment #{h(params[:env])}. Please add to config.yml."
  end

  @public_clusters = Environment.list_public

  @js_host = if params[:js_host]
    # You're probably developing the js and won't be serving it over ssl
    "http://#{params[:js_host]}"
  else
    @ssl ? "https://#{@env[:cdn_https_host]}" : "http://#{@env[:cdn_http_host]}"
  end

  enabled_transports = if params[:transports].is_a?(Array)
    params[:transports]
  else
    supported_transports(@version)
  end
  @selected_transports = Hash[enabled_transports.map { |t| [t, true] }]

  erb :public
end

post '/hello' do
  pusher_env.client.trigger('presence-channel', 'event', {data: 'hello'})
  cache_control "no-cache"
  return 'ok'
end

post '/pusher/auth' do
  content_type :json
  pusher_env.client[params[:channel_name]]
    .authenticate(params[:socket_id], user_id: rand(1000))
    .to_json
end

# Legacy route
get(/^\/(\d+\.\d+(\.\d+[-pre]*)?)\/?$/) do |version, _|
  redirect "/?version=#{version}"
end

helpers do
  def pusher_env
    Environment.new(params[:env] || "mt1")
  end

  def link_to(name, url, options = {})
    "<a href=\"#{url}\" class=\"#{options[:class]}\">#{name}</a>"
  end

  def files(version)
    if version >= '3.0.0'
      %w{pusher.js pusher.min.js json2.js json2.min.js sockjs.js sockjs.min.js}
    elsif version >= '1.12.4'
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
  
  def supported_transports(version)
    if version >= '3.0.0'
      %w{ws xhr_streaming xdr_streaming xhr_polling xdr_polling sockjs}
    else
      %w{ws flash xhr_streaming xdr_streaming xhr_polling xdr_polling sockjs}
    end
  end

  def js_source(js_host, version, file)
    "#{js_host}/#{version}/#{file}"
  end

  def test_config(options = {})
    {
      env: params[:env] || 'mt1',
      version: params[:version] || VERSIONS.last,
      ssl: params.key?("ssl") || nil,
      js_host: params[:js_host],
      transports: params[:transports],
    }.merge(options).select { |k, v| v }
  end

  def test_query_string(options)
    "?#{Rack::Utils.build_nested_query(test_config(options))}"
  end

  def h(text)
    Rack::Utils.escape_html(text)
  end
end
