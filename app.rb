require 'facebook/messenger'
require 'sinatra'
require_relative './bot_logic'

$stdout.sync = true

include Facebook::Messenger

Bot.on :message do |message|
  puts message.inspect
  #message.reply(text: 'Hello, human!')
  BotLogic.instance.handle_message message
end

Bot.on :postback do |message|
  puts message.inspect

  if message.payload == 'RICHIEDI PREVENTIVO'
    BotLogic.instance.handle_message_reset message
  end
end

get '/sessions' do
  BotLogic.instance.sessions.inspect
end

get '/button' do
  erb :button
end
