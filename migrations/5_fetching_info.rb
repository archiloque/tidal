Sequel.migration do
  up do
    add_column :feeds, :last_successful_fetch, DateTime, :null => true
    add_column :feeds, :error_message, String, :null => true
  end
end