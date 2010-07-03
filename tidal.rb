require 'rubygems'
require 'bundler'
Bundler.setup

require 'json'
require 'logger'
require 'tzinfo'
require 'rest_client'
require 'nokogiri'
require 'andand'

require 'sinatra/base'
require 'rack-flash'

require 'builder'

ENV['DATABASE_URL'] ||= "sqlite://#{Dir.pwd}/tidal.sqlite3"
['SUPERFEEDER_LOGIN', 'SUPERFEEDER_PASSWORD', 'SERVER_BASE_URL', 'TIMEZONE'].each do |param|
  unless ENV[param]
    raise "#{param} env parameter is missing"
  end
end
if ENV['SERVER_BASE_URL'][-1, 1] == '/'
  raise "SERVER_BASE_URL env parameter should not end with a '/'"
end


require 'sinatra'
require 'sinatra/sequel'

require 'sequel/extensions/named_timezones'
Sequel.default_timezone = TZInfo::Timezone.get(ENV['TIMEZONE'])
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
  if ENV['LOGGING']
    set :logging, true
    RestClient.log = 'stdout'
  else
    set :logging, false
  end

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
    @js_include = []
  end

  get '/' do
    feeds = Feed.filter(:public => true).order(:category.asc, :name.asc)

    @feeds_per_category = Hash.new { |hash, key| hash[key] = [] }
    @feeds_per_id = {}
    feeds.each do |feed|
      @feeds_per_category[feed.category] << feed
      @feeds_per_id[feed.id] = feed
    end
    @posts = Post.filter('feed_id in (select id from feeds where public is ?)', true).order(:published_at.desc).limit(100)
    erb :'index.html'
  end

  get '/atom' do
    content_type 'application/atom+xml', :charset => 'utf-8'
    builder do |xml|
      xml.instruct! :xml, :version => '1.0'
      xml.feed :xmlns => 'http://www.w3.org/2005/Atom' do
          xml.title 'Tidal, Archiloque\'s feed reader'
          xml.subtitle 'All I read, may or may not be interesting for you'
          xml.link :href => ENV['SERVER_BASE_URL']
          xml.generator 'Tidal', :uri => 'http://github.com/archiloque/tidal'
          xml.id "#{ENV['SERVER_BASE_URL']}/"
          xml.logo '/apple-touch-icon.png'

          last_post = Post.filter('feed_id in (select id from feeds where public is ?)', true).order(:published_at.desc).first
          if last_post
            xml.updated Time.parse(last_post.published_at.to_s).xmlschema
          end

          Post.filter('feed_id in (select id from feeds where public is ?)', true).order(:published_at.desc).limit(50).each do |post|
            xml << post.content
        end
      end
    end
  end

  private

  def log message
    if ENV['LOGGING']
      STDOUT.puts "#{Time.now} #{message}"
    end
  end

end

require 'actions/admin'
require 'actions/login'
require 'actions/reader'
require 'actions/notifications'
