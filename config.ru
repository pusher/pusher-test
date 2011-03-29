$:.push(File.expand_path('..', __FILE__))

require 'app'

use Rack::Static, :urls => ['/WebSocketMain.swf'], :root => "public"

run Sinatra::Application
