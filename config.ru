require 'facebook/messenger'
require_relative 'app'

run Facebook::Messenger::Server
map "/admin" do
  run(Sinatra::Application)
end

map "/" do
  run(Facebook::Messenger::Server)
end
