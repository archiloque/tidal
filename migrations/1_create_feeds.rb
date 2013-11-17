Sequel.migration do
  up do
    create_table :feeds do
      primary_key :id, :type => Integer, :null => false
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
end