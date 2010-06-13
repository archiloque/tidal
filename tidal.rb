require 'rubygems'
require 'bundler'
Bundler.setup

require 'json'
require 'logger'
require 'tzinfo'
require 'rest_client'
require 'nokogiri'

require 'sinatra/base'
require 'rack-flash'

ENV['DATABASE_URL'] ||= "sqlite://#{Dir.pwd}/tidal.sqlite3"
['SUPERFEEDER_LOGIN', 'SUPERFEEDER_PASSWORD', 'SERVER_BASE_URL'].each do |param|
  unless ENV[param]
    raise "#{param} env parameter is missing"
  end
end

require 'sinatra'
require 'sinatra/sequel'

require 'sequel/extensions/named_timezones'
Sequel.default_timezone = TZInfo::Timezone.get('Europe/Paris')
Sequel::Model.raise_on_save_failure = true
require 'erb'

module Sequel
  class Database
    def table_exists?(name)
      begin
        from(name).first
        true
      rescue Exception
        false
      end
    end
  end
end

class Tidal < Sinatra::Base

  set :views, File.dirname(__FILE__) + '/views'
  set :public, File.dirname(__FILE__) + '/public'
  set :raise_errors, true
  set :show_exceptions, :true

  root_dir = File.dirname(__FILE__)
  set :app_file, File.join(root_dir, 'tidal.rb')

  configure :development do
    database.loggers << Logger.new(STDOUT)
  end

  # open id
  use Rack::Session::Pool
  require 'rack/openid'
  use Rack::OpenID

  require 'lib/models'
  require 'lib/helpers'
  helpers Sinatra::TidalHelper

  use Rack::Flash

  before do
    @user_logged = session[:user]
    @js_include = ['jquery', 'tidal']
    @css_include = ['tidal']
  end

  get '/' do
  end

end

require 'actions/admin'
require 'actions/login'
require 'actions/notifications'
