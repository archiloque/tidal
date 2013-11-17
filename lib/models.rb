Sequel::Model.plugin :validation_helpers

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

  def validateen
    validates_presence :published_at
    validates_presence :feed_id
  end

end

