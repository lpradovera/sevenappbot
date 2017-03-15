require 'facebook/messenger'
task :set_cta do
  include Facebook::Messenger
  puts 'setting call to action'
  Facebook::Messenger::Thread.set({
    setting_type: 'call_to_actions',
    thread_state: 'existing_thread',
    call_to_actions: [
      {
        type: 'postback',
        title: 'Richiedi un preventivo',
        payload: 'RICHIEDI PREVENTIVO'
      },
      {
        type: 'web_url',
        title: 'Sito web 7App,it',
        url: 'http://www.7app.it/'
      }
    ]
  }, access_token: ENV['ACCESS_TOKEN'])

  puts "setting greeting"
  Facebook::Messenger::Thread.set({
    setting_type: 'greeting',
    greeting: {
      text: 'Ciao {{user_first_name}}! 7App è specializzata nello sviluppo di applicazioni mobile native (iOS e Android ) e nella realizzazione di piattaforme web responsive.'
    },
  }, access_token: ENV['ACCESS_TOKEN'])
end


task :unset_cta do
  include Facebook::Messenger
  puts 'unsetting call to action'
  Facebook::Messenger::Thread.unset({
    setting_type: 'call_to_actions',
    thread_state: 'existing_thread',
  }, access_token: ENV['ACCESS_TOKEN'])

   Facebook::Messenger::Thread.unset({
    setting_type: 'greeting',
  }, access_token: ENV['ACCESS_TOKEN'])
end
