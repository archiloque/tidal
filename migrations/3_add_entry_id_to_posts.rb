Sequel.migration do
  up do
    add_column :posts, :entry_id, String, :size => 250, :null => true, :index => true, :unique => false
    run 'delete from posts'
  end
end