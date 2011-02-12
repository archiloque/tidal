require 'rubygems'
require 'bundler'
Bundler.setup
require 'rest_client'

unless ENV['SERVER_BASE_URL']
  raise "'SERVER_BASE_URL' env parameter is missing"
end

task :cron do
  p RestClient.post "#{ENV['SERVER_BASE_URL']}/purge", {}
end