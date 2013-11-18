require 'rest_client'

unless ENV['SERVER_BASE_URL']
  raise "'SERVER_BASE_URL' env parameter is missing"
end

task :cron do
  p RestClient.get "#{ENV['SERVER_BASE_URL']}/fetch", {}
  p RestClient.post "#{ENV['SERVER_BASE_URL']}/purge", {}
end
