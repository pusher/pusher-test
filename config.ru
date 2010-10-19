require 'app'

use Rack::Static, :urls => ['/WebSocketMain.swf'], :root => "public"

run Sinatra::Application
