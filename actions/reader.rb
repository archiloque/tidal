# The actions of the reader part
class Tidal

  get '/reader' do
    if check_logged
      @js_include += ['jquery', 'tidal']
      @title = 'reader'
      @posts = Post.
          join(:feeds, :id => :feed_id).
          filter('posts.read = ?', false).
          order(:category, :name, Sequel.desc(:published_at)).
          select_all(:posts)

      @feeds_per_id = {}
      Feed.each do |feed|
        @feeds_per_id[feed.id] = feed
      end
      erb :'reader.html'
    end
  end

  post '/reader' do
    unless params[:displayedIds].blank?
      Post.filter(:id => params[:displayedIds].split(',').collect{|i| i.to_i }).update(:read => true)
    end
    redirect '/reader'
  end

end
