require 'uri'
require 'net/http'

unless ENV['SERVER_BASE_URL']
  raise "'SERVER_BASE_URL' env parameter is missing"
end

task :cron do
  p Net::HTTP.get(URI("#{ENV['SERVER_BASE_URL']}/fetch"))
end
