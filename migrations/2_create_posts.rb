Sequel.migration do
  up do
    create_table :posts do
      primary_key :id, :type => Integer, :null => false
      DateTime :published_at, :null => false, :index => true, :unique => false
      Text :content, :text => true
      foreign_key :feed_id, :feeds
      boolean :read, :null => true, :default => false, :index => true, :unique => false

    end
  end
end