require 'sendgrid-ruby'
require 'pp'
require 'singleton'
require 'gibbon'

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

  def handle_message_reset(message)
    puts "RESTARTING SESSION ON POSTBACK"
    session = find_session message.sender['id']
    session[:step] = :greeting
    handle_message_action(session, message)
  end

  def handle_message_action(session, message)
    puts message.inspect
    puts session.inspect
    if %i{greeting greeting_choice web_or_app_choice web_or_app web app altro altro_response web_choice app_choice budget budget_choice email_yesno email_choice email_request email_input phone_yesno phone_choice phone_request phone_input mailing_choice mailing_yesno}.include?(session[:step])
      puts "Executing #{session[:step]}"
      self.send("handle_#{session[:step]}".to_sym, session, message)
    else
      generic_error(session, message)
    end
  end

  def handle_greeting(session, message)
    set_call_to_action
    message.reply(text: 'Ciao! Sono il bot di 7App.')
    message.reply(
      text: 'Sei...',
      quick_replies: [
        {
          content_type: 'text',
          title: 'Azienda',
          payload: 'AZIENDA'
        },
        {
          content_type: 'text',
          title: "Privato",
          payload: 'PRIVATO'
        }
      ]
    )
    session[:step] = :greeting_choice
  end


  def handle_greeting_choice(session, message)
    session[:type] = message.quick_reply
    session[:step] = :web_or_app_choice
    handle_message_action(session, message)
  end


  def handle_web_or_app_choice(session, message)
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
        },
        {
          content_type: 'text',
          title: "Altro",
          payload: 'ALTRO'
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
    elsif message.quick_reply == 'ALTRO'
      session[:path] = 'altro'
      session[:step] = :altro
      handle_message_action(session, message)
    else
      generic_error(session, message)
      session[:step] = :greeting
      handle_greeting(session, message)
    end
  end

  def handle_altro(session, message)
    message.reply(text: 'Bene! Puoi spiegarci cosa ti serve?')
    session[:step] = :altro_response
  end

  def handle_altro_response(session, message)
    session[:choice] = message.text
    session[:step] = :email_yesno
    handle_message_action(session, message)
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
          title: session[:type] == 'AZIENDA' ? '5.000 €' : '3.000 €',
          payload:  session[:type] == 'AZIENDA' ? '5000' : '3000',
        },
        {
          content_type: 'text',
          title: '10.000 €',
          payload: '10000'
        },
        {
          content_type: 'text',
          title: '20.000+ €',
          payload: '20000'
        }
      ]
    )
    session[:step] = :budget_choice
  end

  def handle_budget_choice(session, message)
    session[:budget] = message.quick_reply
    session[:step] = :email_yesno
    handle_message_action(session, message)
  end

  def handle_email_yesno(session, message)
    message.reply(
      text: 'Vuoi essere contattato via email?',
      quick_replies: [
        {
          content_type: 'text',
          title: 'Sì',
          payload: 'SI'
        },
        {
          content_type: 'text',
          title: "No",
          payload: 'NO'
        }
      ]
    )
    session[:step] = :email_choice
  end

  def handle_email_choice(session, message)
    if message.quick_reply == 'SI'
      session[:step] = :email_request
      handle_message_action(session, message)
    else
      session[:step] = :phone_yesno
      handle_message_action(session, message)
    end
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
      message.reply(text: 'Riceverai la nostra corporate brochure a questo indirizzo email. Grazie!')
      session[:step] = :mailing_yesno
      handle_message_action(session, message)
    else
      message.reply(text: "Mi dispiace, l'email inserita non è valida.")
    end
  end

  def handle_mailing_yesno(session, message)
    message.reply(
      text: 'Desideri iscriverti alla nostra newsletter?',
      quick_replies: [
        {
          content_type: 'text',
          title: 'Sì',
          payload: 'SI'
        },
        {
          content_type: 'text',
          title: "No",
          payload: 'NO'
        }
      ]
    )
    session[:step] = :mailing_choice
  end

  def handle_mailing_choice(session, message)
    if message.quick_reply == 'SI'
      message.reply(text: 'Grazie!')
      session[:subscribe_ml] = true
      subscribe_mailing_list(session)
    end
    session[:step] = :phone_yesno
    handle_message_action(session, message)
  end

  def handle_phone_yesno(session, message)
    message.reply(
      text: 'Preferisci essere contattato telefonicamente?',
      quick_replies: [
        {
          content_type: 'text',
          title: 'Sì',
          payload: 'SI'
        },
        {
          content_type: 'text',
          title: "No",
          payload: 'NO'
        }
      ]
    )
    session[:step] = :phone_choice
  end

  def handle_phone_choice(session, message)
    if message.quick_reply == 'SI'
      session[:step] = :phone_request
      handle_message_action(session, message)
    else
      end_conversation(session, message)
    end
  end

  def handle_phone_request(session, message)
    session[:step] = :phone_input
    message.reply(text: 'Inserisci di seguito il tuo numero.')
  end

  def handle_phone_input(session, message)
    phone = message.text
    if validate_phone(phone)
      message.reply(text: 'Ti chiamerò personalmente nei prossimi giorni. Grazie!')
      session[:phone] = phone
      end_conversation(session, message)
    else
      message.reply(text: "Mi dispiace, il numero inserito non è valido.")
    end
  end

  def validate_phone(phone)
    !!phone.to_s.match(/^\A[0|3]{1}[0-9]{5,10}\Z/)
  end

  def validate_email(email)
    !!email.to_s.match(/\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/)
  end

  def subscribe_mailing_list(session)
    gibbon = Gibbon::Request.new(api_key: ENV['MAILCHIMP_API_KEY'], debug: true)
    puts gibbon.lists(ENV['MAILCHIMP_LIST_ID']).members.create(body: {email_address: session[:email], status: "subscribed"}) rescue nil
  end

  def send_email(session, email)
    from = Email.new(email: 'biz@7app.it')
    subject = 'Message Request from Facebook Bot'
    to = Email.new(email:  ENV['EMAIL_DEST'])
    content = Content.new(type: 'text/plain', value: format_message(session))
    mail = Mail.new(from, subject, to, content)

    from = Email.new(email: 'biz@7app.it')
    subject = '7App Facebook Bot'
    to = Email.new(email: session[:email])
    content = Content.new(type: 'text/plain', value: format_user_message(session))
    user_mail = Mail.new(from, subject, to, content)

    sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])

    puts "Sending #{mail.to_json}"
    response = sg.client.mail._('send').post(request_body: mail.to_json)

    puts "Sending #{user_mail.to_json}"
    response = sg.client.mail._('send').post(request_body: user_mail.to_json)
  end

  def format_message(session)
    <<~HERE
      Email: #{session[:email]}
      Telefono: #{session[:phone]}
      Richiesta: #{session[:path]}
      Tipo: #{session[:choice]}
      Budget: #{session[:budget]}
    HERE
  end

  def format_user_message(session)
    <<~HERE
      Ti ringraziamo per aver contattato 7App.

      Puoi scaricare la nostra corporate brochure al seguente indirizzo: https://goo.gl/alBwUn

      La tua richiesta:

      Email: #{session[:email]}

      Telefono: #{session[:phone]}

      Richiesta: #{session[:path]}

      Tipo: #{session[:choice]}

      Budget: #{session[:budget]}

      Cordiali saluti,

      7App

      https://www.7app.it/
    HERE
  end

  def end_conversation(session, message)
    if !session[:email] && !session[:phone]
      message.reply(text: "Grazie dallo staff 7App! Non ci hai fornito nessun metodo per contattarti, per cui ti chiediamo di scrivere a biz@7app.it.")
    else
      message.reply(text: "Grazie dallo staff 7App!")
    end
    session[:step] = :greeting
  end

  def generic_error(session, message)
    message.reply(text: 'Scusami! Non ho capito.')
  end

  def set_call_to_action
  end

  def find_session(id)
    if session = sessions[id]
      session
    else
      sessions[id] = {created_at: Time.now, step: :greeting}
    end
  end
end

