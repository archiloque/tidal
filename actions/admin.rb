class Tidal

  get '/admin' do
    if check_logged
      @title = 'Configuration'
      @categories = database['select distinct(category) c from feeds order by category'].map(:c)
      @feeds = Feed.order(:catgeroy.asc).order(:name.asc)
      @css_include << 'admin'
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
                           :display_content => params[:display_content])
        result = superfeedr_request(params[:feed_uri], feed.id, 'subscribe')
        if result.code == 202
          flash[:notice] = 'Feed added'
        else
          flash[:error] = "Failure while adding feed #{params[:name]}: return code #{result.code},  #{result}"
        end
      rescue Sequel::ValidationFailed => e
        flash[:error] = "Error during feed creation #{e}"
      end
      redirect '/admin'
    end
  end

  post '/admin/delete' do
    if check_logged
      feed = Feed.where(:id => params[:feed]).first
      if feed
        result = superfeedr_request(params[:feed_uri], feed.id, 'unsubscribe')
        if result.code == 202
          flash[:notice] = 'Feed removed'
        else
          flash[:error] = "Failure while removing feed #{params[:name]}: return code #{result.code},  #{result}"
        end
        Post(:feed_id => feed.id).delete
        Feed(:id => feed.id).delete
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
                      :display_content => params[:display_content])
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
      flash[:notice] = "Category renamed"
      redirect '/admin'
    end
  end

  private

  def superfeedr_request feed_uri, feed_id, action
    RestClient::Request.execute(:method => :post,
                                :url => 'https://superfeedr.com/hubbub',
                                :payload => {'hub.mode'  => action,
                                             'hub.verify' => 'async',
                                             'hub.topic' => feed_uri,
                                             'hub.callback' => "#{ENV['SERVER_BASE_URL']}/callback/#{feed_id}"},
                                :user => ENV['SUPERFEEDER_LOGIN'],
                                :password => ENV['SUPERFEEDER_PASSWORD'])
  end

end