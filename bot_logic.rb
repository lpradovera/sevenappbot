require 'sendgrid-ruby'
require 'pp'
class BotLogic
  include Singleton
  include SendGrid
  attr_accessor :sessions

  def initialize
    @sessions = {}
  end

  def handle_message(message)
    session = find_session message.sender['id']
    handle_message_action(session, message)
  end

  def handle_message_action(session, message)
    puts message.inspect
    puts session.inspect
    if %i{greeting web_or_app web app web_choice app_choice budget budget_choice email_request email_input}.include?(session[:step])
      puts "Executing #{session[:step]}"
      self.send("handle_#{session[:step]}".to_sym, session, message)
    else
      generic_error(session, message)
    end
  end

  def handle_greeting(session, message)
    message.reply(text: 'Ciao! Sono il bot di 7App.')
    message.reply(text: 'Siamo specializzati nello sviluppo di applicazioni mobile native (iOS e Android ) e nella realizzazione di piattaforme web responsive.')
    message.reply(
      text: 'Come posso aiutarti? Hai bisogno di...',
      quick_replies: [
        {
          content_type: 'text',
          title: 'Un sito?',
          payload: 'SITOWEB'
        },
        {
          content_type: 'text',
          title: "Un'app?",
          payload: 'APP'
        }
      ]
    )
    session[:step] = :web_or_app
  end

  def handle_web_or_app(session, message)
    if message.quick_reply == 'SITOWEB'
      session[:path] = 'web'
      session[:step] = :web
      handle_message_action(session, message)
    elsif message.quick_reply == 'APP'
      session[:path] = 'app'
      session[:step] = :app
      handle_message_action(session, message)
    else
      generic_error(session, message)
      session[:step] = :greeting
      handle_greeting(session, message)
    end
  end

  def web_message(message)
     message.reply(
      text: 'Come posso aiutarti? Hai bisogno di un sito...',
      quick_replies: [
        {
          content_type: 'text',
          title: 'Statico o dinamico',
          payload: 'STATICO'
        },
        {
          content_type: 'text',
          title: "Wordpress",
          payload: 'WORDPRESS'
        },
        {
          content_type: 'text',
          title: "Ecommerce",
          payload: 'ECOMMERCE'
        }
      ]
    )
  end

  def handle_web(session, message)
    web_message(message)
    session[:step] = :web_choice
  end

  def handle_app(session, message)
    message.reply(
      text: 'Come posso aiutarti? Hai bisogno di una app...',
      quick_replies: [
        {
          content_type: 'text',
          title: 'iOS',
          payload: 'IOS'
        },
        {
          content_type: 'text',
          title: "Android",
          payload: 'ANDROID'
        },
        {
          content_type: 'text',
          title: "Entrambe",
          payload: 'ENTRAMBE'
        }
      ]
    )
    session[:step] = :web_choice
  end

  def handle_web_choice(session, message)
    puts "this happens"
    session[:choice] = message.quick_reply
    session[:step] = :budget
    handle_message_action(session, message)
  end

  def handle_budget(session, message)
    message.reply(
      text: 'Che budget hai in mente?',
      quick_replies: [
        {
          content_type: 'text',
          title: '5.000',
          payload: '5000'
        },
        {
          content_type: 'text',
          title: '10.000',
          payload: '10000'
        },
        {
          content_type: 'text',
          title: '20.000+',
          payload: '20000'
        }
      ]
    )
    session[:step] = :budget_choice
  end

  def handle_budget_choice(session, message)
    session[:budget] = message.quick_reply
    session[:step] = :email_request
    handle_message_action(session, message)
  end

  def handle_email_request(session, message)
    session[:step] = :email_input
    message.reply(text: 'Mi lasci la tua email?')
  end

  def handle_email_input(session, message)
    email = message.text
    if validate_email(email)
      session[:email] = email
      send_email(session, email)
      message.reply(text: 'Riceverai la nostra corporate brochure a questo indirizzo email (ripetete) e ti chiamerò personalmente nei prossimi giorni. Grazie!')
      session[:step] = :greeting
    else
      message.reply(text: "Mi dispiace, l'email inserita non è valida.")
    end
  end

  def validate_email(email)
    !!email.to_s.match(/\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/)
  end

  def send_email(session, email)
    from = Email.new(email: 'biz@7app.it')
    subject = 'Message Request from Facebook Bot'
    to = Email.new(email:  ENV['EMAIL_DEST'])
    content = Content.new(type: 'text/plain', value: format_message(session))
    mail = Mail.new(from, subject, to, content)

    puts "Sending #{mail.to_json}"

    sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
    response = sg.client.mail._('send').post(request_body: mail.to_json)
  end

  def format_message(session)
    <<~HERE
      Email: #{session[:email]}
      Richiesta: #{session[:path]}
      Tipo: #{session[:choice]}
      Budget: #{session[:budget]}
    HERE
  end

  def generic_error(session, message)
    message.reply(text: 'Scusami! Non ho capito.')
  end

  def find_session(id)
    if session = sessions[id]
      session
    else
      sessions[id] = {created_at: Time.now, step: :greeting}
    end
  end
end

