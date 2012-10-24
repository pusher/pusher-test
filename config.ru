$:.push(File.expand_path('..', __FILE__))

require 'app'

run Sinatra::Application
