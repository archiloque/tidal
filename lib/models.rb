Sequel::Model.plugin :validation_helpers

migration 'create table users' do
  database.create_table :users do
    primary_key :openid_identifier, :type => String, :null => false, :auto_increment => false
  end
end

migration 'create table meta' do
  database.create_table :metas do
    primary_key :name, :type => String, :null => false, :auto_increment => false
    Text :value, :null => true
  end
end

migration 'create table feeds' do
  database.create_table :feeds do
    primary_key :id, :type=>Integer, :null => false
    String :name, :size => 250, :null => true, :index => true, :unique => true
    String :category, :size => 250, :null => false, :index => true, :unique => false
    String :site_uri, :size => 250, :null => false
    String :feed_uri, :size => 250, :null => false
    boolean :display_content, :null => false
    DateTime :last_notification, :null => true
    boolean :public, :null => false
  end
end

migration 'create table posts' do
  database.create_table :posts do
    primary_key :id, :type=>Integer, :null => false
    DateTime :published_at, :null => false, :index => true, :unique => false
    Text :content, :text => true
    foreign_key :feed_id, :feeds
    boolean :read, :null => true, :default => false
  end
end

class User < Sequel::Model
  def validate
    begin
      URI.parse openid_identifier
    rescue URI::InvalidURIError
      errors.add('', '[#{openid_identifier} is not a valid address')
    end
  end
end

class Meta < Sequel::Model
  def validate
    validates_unique :name
    validates_presence :name
  end
end

class Feed < Sequel::Model
  one_to_many :posts

  def validate

    validates_unique :name
    validates_presence :name
    validates_presence :site_uri
    validates_presence :feed_uri
    validates_presence :public
    validates_presence :display_content

    begin
      URI.parse site_uri
    rescue URI::InvalidURIError
      errors.add('site_uri', "[#{site_uri} is not a valid uri")
    end
    begin
      URI.parse feed_uri
    rescue URI::InvalidURIError
      errors.add('feed_uri', "[#{feed_uri} is not a valid uri")
    end
  end

end

class Post < Sequel::Model
  many_to_one :feed

  def validate
    validates_presence :content
    validates_presence :published_at
    validates_presence :feed_id
  end

end

