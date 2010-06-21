# The action for the administration pages
class Tidal

  get '/admin' do
    if check_logged
      @title = 'Configuration'
      @categories = database['select distinct(category) as c from feeds order by category'].map(:c)
      @feeds = Feed.order(:category.asc, :name.asc)
      @js_include += ['jquery', 'tidal']
      erb :'admin.html'
    end
  end

  post '/admin/add' do
    if check_logged
      category = params[:category_text].blank? ? params[:category_select] : params[:category_text]
      begin
        feed = Feed.create(:name => params[:name],
                           :category => category,
                           :site_uri => params[:site_uri],
                           :feed_uri => params[:feed_uri],
                           :display_content => params[:display_content] || false,
                           :public => params[:public] || false,
                           :subscription_validated => false)
        flash[:notice] = 'Feed added, subscription following'
        superfeedr_request([{:uri => params[:feed_uri], :id => feed.id}], 'subscribe')
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
        superfeedr_request([{:uri => params[:feed_uri], :id => feed.id}], 'unsubscribe')
        Post(:feed_id => feed.id).delete
        Feed(:id => feed.id).delete
        flash[:notice] = 'Feed removed, unsubscription following'
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
      added_feeds = []
      Nokogiri::XML(params[:file][:tempfile]).css('outline[xmlUrl]').each do |outline|
        if Feed.where(:site_uri => outline['htmlUrl']).first
          duplicates += 1
        else
          site_uri = outline['htmlUrl']
          if site_uri.blank?
            feed = URI.parse(outline['xmlUrl'])
            site_uri = "#{feed.scheme}://#{feed.host}#{(feed.port == 80) ? '' : ":#{feed.port}"}/"
          end
          feed = Feed.create(:name => outline['title'],
                             :category => outline.parent['text'] || '',
                             :site_uri => site_uri,
                             :feed_uri => outline['xmlUrl'],
                             :display_content => true,
                             :public => true,
                             :subscription_validated => false)
          added_feeds << {:uri => outline['xmlUrl'], :id => feed.id}
          feeds_number += 1
        end
      end
      superfeedr_request(added_feeds, 'subscribe')
      flash[:notice] = "#{feeds_number.to_s} feeds added and #{duplicates_number} duplicates, subscription following"
      log "opml file included"
      redirect '/admin'
    end
  end

  post '/purge' do
    Post.filter({:read => true} & (:published_at <= (DateTime.now - 7))).delete
  end

  private

  # do a superfeedr request
  # feeds is an array of {:uri, :db_id}
  def superfeedr_request feeds, action
    Thread.new(feeds, action) do
      feeds.each do |feed|
        log "calling superfeedr #{action} for #{feed[:uri]}"
        result = RestClient::Request.execute(:method => :post,
                                             :url => 'http://superfeedr.com/hubbub',
                                             :payload => {'hub.mode'  => action,
                                                          'hub.verify' => 'async',
                                                          'hub.topic' => feed[:uri],
                                                          'hub.callback' => "#{ENV['SERVER_BASE_URL']}/callback/#{feed[:id]}"},
                                             :user => ENV['SUPERFEEDER_LOGIN'],
                                             :password => ENV['SUPERFEEDER_PASSWORD'])
        if result.code == 202
          log "Feed #{feed[:uri]} #{action} ok"
        else
          log "Error with feed #{feed[:uri]} #{action} error: return code #{result.code}, #{result}"
        end
      end
    end
  end

end