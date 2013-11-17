Sequel.migration do
  up do
    drop_column :feeds, :last_notification
    drop_column :feeds, :subscription_validated

    add_column :feeds, :last_fetch, DateTime, :null => true, :index => true, :unique => false
    run 'update feeds set last_fetch = now()'
    set_column_type :feeds, :last_fetch, DateTime, :null => false
    add_index :feeds, :feed_uri, :unique => true
    add_column :feeds, :last_post, DateTime, :null => true
    run 'update feeds set last_post = (select max(published_at) from posts where posts.feed_id = feeds.id)'
    run 'delete from posts'
    add_column :posts, :title, String, :null => true
    add_column :posts, :uri, String, :null => true
    set_column_type :posts, :content, String, :null => true
  end
end