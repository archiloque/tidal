Sequel::Model.plugin :validation_helpers

migration 'create table feeds' do
  database.create_table :feeds do
    primary_key :id, :type=>Integer, :null => false
    String :name, :size => 250, :null => true, :index => true, :unique => true
    String :category, :size => 250, :null => false, :index => true, :unique => false
    String :site_uri, :size => 250, :null => false
    String :feed_uri, :size => 250, :null => false
    boolean :display_content, :null => false
    DateTime :last_notification, :null => true
    boolean :public, :null => false, :index => true, :unique => false
    boolean :subscription_validated, :null => false
  end
end

migration 'create table posts' do
  database.create_table :posts do
    primary_key :id, :type=>Integer, :null => false
    DateTime :published_at, :null => false, :index => true, :unique => false
    Text :content, :text => true
    foreign_key :feed_id, :feeds
    boolean :read, :null => true, :default => false, :index => true, :unique => false
  end
end

migration 'add post entry_id' do
  database.add_column :posts, :entry_id, String, :size => 250, :null => true, :index => true, :unique => false

  database['select id as id, content as content from posts'].each do |row|
    parsed_post = Nokogiri::XML(row[:content])
    entry_id = parsed_post.xpath('/entry/id')[0].content
    if entry_id
      database['update posts set entry_id = ? where id = ?', entry_id, row[:id]].each do |row|
      end
    end
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

