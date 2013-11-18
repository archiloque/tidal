# The action for the administration pages
class Tidal

  get '/admin' do
    if check_logged
      @title = 'Administration'
      @categories = DATABASE['select distinct(category) as c from feeds order by category'].map(:c)
      @feeds = Feed.order(:category, :name)
      @js_include += ['jquery', 'tidal']
      erb :'admin.html'
    end
  end

  post '/admin/add' do
    if check_logged
      category = params[:category_text].blank? ? params[:category_select] : params[:category_text]
      begin
        Feed.create(:name => params[:name],
                    :category => category,
                    :site_uri => params[:site_uri],
                    :feed_uri => params[:feed_uri],
                    :display_content => params[:display_content] || false,
                    :public => params[:public] || false,
                    :last_fetch => DateTime.civil(1900, 1, 1))
        flash[:notice] = 'Feed added'
        fetch_feed params[:feed_uri]
      rescue Sequel::ValidationFailed => e
        flash[:error] = "Error during feed creation #{e}"
      end
      log "#{params[:name]} added"
      redirect '/admin'
    end
  end

  post '/admin/remove' do
    if check_logged
      feed = Feed.where(:id => params[:feed]).first
      if feed
        Post.where(:feed_id => feed.id).delete
        Feed.where(:id => feed.id).delete
        flash[:notice] = 'Feed removed'
      else
        flash[:notice] = 'Feed not found'
      end
      redirect '/admin'
    end
  end

  post '/admin/edit_feed' do
    if check_logged
      feed = Feed.where(:id => params[:feed]).first
      if feed
        begin
          feed.update(:name => params[:name],
                      :category => params[:category],
                      :site_uri => params[:site_uri],
                      :feed_uri => params[:feed_uri],
                      :display_content => params[:display_content] || false,
                      :public => params[:public] || false)
          flash[:notice] = 'Feed updated'
        rescue Sequel::ValidationFailed => e
          flash[:error] = "Error during feed update #{e}"
        end
      else
        flash[:notice] = 'Feed not found'
      end
      redirect '/admin'
    end
  end

  post '/admin/rename_category' do
    if check_logged
      Feed.where(:category => params[:category_before]).update(:category => params[:category_after])
      flash[:notice] = 'Category renamed'
      redirect '/admin'
    end
  end

  post '/admin/upload_opml' do
    if check_logged
      feeds_number = 0
      duplicates_number = 0
      Nokogiri::XML(params[:file][:tempfile]).css('outline[xmlUrl]').each do |outline|
        if Feed.where(:site_uri => outline['htmlUrl']).first
          duplicates += 1
        else
          site_uri = outline['htmlUrl']
          if site_uri.blank?
            feed = URI.parse(outline['xmlUrl'])
            site_uri = "#{feed.scheme}://#{feed.host}#{(feed.port == 80) ? '' : ":#{feed.port}"}/"
          end
          Feed.create(:name => outline['title'],
                      :category => outline.parent['text'] || '',
                      :site_uri => site_uri,
                      :feed_uri => outline['xmlUrl'],
                      :display_content => true,
                      :public => true)
          feeds_number += 1
        end
      end
      flash[:notice] = "#{feeds_number.to_s} feeds added and #{duplicates_number} duplicates"
      log "opml file included"
      redirect '/admin'
    end
  end

  post '/purge' do
    Post.where('read = ? and published_at <= ?', true, (DateTime.now - 7)).delete
    "OK"
  end

end