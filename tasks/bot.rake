require 'facebook/messenger'
task :set_cta do
  include Facebook::Messenger
  puts 'setting call to action'
  puts Facebook::Messenger::Thread.set({
    setting_type: 'call_to_actions',
    thread_state: 'existing_thread',
    call_to_actions: [
      {
        type: 'web_url',
        title: 'Sito web',
        url: 'http://7app.it/'
      }
    ]
  }, access_token: ENV['ACCESS_TOKEN'])
end


task :unset_cta do
  include Facebook::Messenger
  puts 'unsetting call to action'
  puts Facebook::Messenger::Thread.unset({
    setting_type: 'call_to_actions',
    thread_state: 'existing_thread',
  }, access_token: ENV['ACCESS_TOKEN'])
end
