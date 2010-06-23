# The actions of the reader part
class Tidal

  get '/reader' do
    if check_logged
      @js_include += ['jquery', 'tidal']
      @title = 'reader'
      erb :'reader.html'
    end
  end

  get '/reader/feeds_info' do
    feeds_per_category = []
    current_category = -1
    current_count = 0;
    database['select feeds.id as id, feeds.category as category, feeds.name as name, feeds.display_content as display_content, feeds.site_uri as site_uri, count(posts.id) as count ' +
            'from feeds ' +
            'left join posts on feeds.id = posts.feed_id and posts.read = ? ' +
            'group by feeds.id, feeds.category, feeds.name, feeds.display_content, feeds.site_uri ' +
            'order by feeds.category, feeds.name', false].each do |row|
      if row[:category] != current_category
        if current_category != -1
          feeds_per_category.last[:count] = current_count
        end
        current_category = row[:category]
        feeds_per_category << {:name => (current_category || ''), :feeds => []}
        current_count = 0
      end
      current_count += row[:count]
      feeds_per_category.last[:feeds] << {:id => row[:id],
                                          :name => row[:name],
                                          :count => row[:count],
                                          :display_content => row[:display_content],
                                          :site_uri => row[:site_uri]}
    end
    if current_category != -1
      feeds_per_category.last[:count] = current_count
    end
    halt 200, {'Content-Type' => 'application/json'}, feeds_per_category.to_json
  end

  get '/reader/render/all' do
    render_posts ['select posts.id as id, posts.published_at as published_at, posts.content as content, posts.feed_id as feed_id ' +
            'from posts, feeds where feeds.id = posts.feed_id and posts.read = ? order by feeds.category, feeds.name, posts.published_at', false]
  end

  get '/reader/render/category' do
    render_posts ['select posts.id as id, posts.published_at as published_at, posts.content as content, posts.feed_id as feed_id ' +
            'from posts, feeds where feeds.id = posts.feed_id and posts.read = ? and feeds.category = ? order by feeds.category, feeds.name, posts.published_at', false, params[:name]]
  end

  get '/reader/render/feed/:id' do
    render_posts ['select posts.id as id, posts.published_at as published_at, posts.content as content, posts.feed_id as feed_id ' +
            'from posts, feeds where feeds.id = posts.feed_id and posts.read = ? and feeds.id = ? order by feeds.category, feeds.name, posts.published_at', false, params[:id]]
  end

  get '/reader/postsRead' do
    if params[:displayedIds]
      Post.filter(:id => params[:displayedIds]).update(:read => true)
    end
    halt "OK"
  end

  private

  def render_posts query
    if params[:displayedIds]
      Post.filter(:id => params[:displayedIds]).update(:read => true)
    end
    posts_per_feeds = []
    current_feed = -1
    database[* query].each do |row|
      if row[:feed_id] != current_feed
        current_feed = row[:feed_id]
        posts_per_feeds << {:id => current_feed, :posts => []}
      end
      parsed_post = Nokogiri::XML(row[:content])
      title = parsed_post.xpath('/entry/title')[0].content
      link = parsed_post.xpath('/entry/link[@type=\'text/html\']')[0]
      content = parsed_post.xpath('/entry/summary')[0].andand.content || parsed_post.xpath('/entry/content')[0].andand.content
      if link
        link = link['href']
      end
      posts_per_feeds.last[:posts] << {:published_at => row[:published_at].strftime("%d/%m %H:%M"),
                                       :title => title,
                                       :link => link,
                                       :id => row[:id],
                                       :content => content}
    end
    halt 200, {'Content-Type' => 'application/json'}, posts_per_feeds.to_json
  end

end
