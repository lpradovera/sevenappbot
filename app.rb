require 'facebook/messenger'
require 'singleton'
require 'sinatra'
require_relative './bot_logic'

$stdout.sync = true

include Facebook::Messenger


Bot.on :message do |message|
  puts message.inspect
  #message.reply(text: 'Hello, human!')
  BotLogic.instance.handle_message message
end

get '/sessions' do
  BotLogic.instance.sessions.inspect
end
