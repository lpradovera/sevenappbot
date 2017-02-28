require 'facebook/messenger'

include Facebook::Messenger

class BotLogic
  def self.send_message(recipient, message)
    Bot.deliver(
      recipient: recipient,
      message: message
    )
  end

  def self.text_only_message(recipient, text_message)
    message = {
      text: text_message
    }
    send_message(recipient, message)
  end
end

Bot.on :message do |message|
  BotLogic.text_only_message(message.sender, 'Hello, human!')
end
