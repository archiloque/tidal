# The actions of the reader part
class Tidal

  get '/reader' do
    if check_logged
      erb :'reader.html'
    end
  end

  get '/reader/feeds_info' do
    feeds_per_category = []
    current_category = -1
    database['select feeds.id id, feeds.category category, feeds.name name, feeds.display_content display_content count(posts.id) count from feeds ' +
            'left join posts on feeds.id = posts.feed_id and posts.read = ? group by feeds.id order by feeds.category, feeds.name', false].each do |row|
      if row[:category] != current_category
        feeds_per_category << [row[:category] || '']
        current_category = row[:category]
      end
      feeds_per_category.last << {:id => row[:id], :name => row[:name], :count => row[:count], :display_content => row[:display_content]}
    end
    halt 200, {'Content-Type' => 'application/json'}, feeds_per_category.to_json
  end

  post '/reader/render/all' do
    render_posts ['select posts.id id, posts.published_at published_at, posts.content content, posts.feed_id feed_id ' +
            'from posts, feeds where feeds.id = posts.feed_id and posts.read = ? order by feeds.category, feeds.name', false]
  end

  post '/reader/render/category' do
    render_posts ['select posts.id id, posts.published_at published_at, posts.content content, posts.feed_id feed_id ' +
            'from posts, feeds where feeds.id = posts.feed_id and posts.read = ? and feeds.category = ? order by feeds.category, feeds.name', false, params[:name]]
  end

  post '/reader/render/feed' do
    render_posts ['select posts.id id, posts.published_at published_at, posts.content content, posts.feed_id feed_id ' +
            'from posts, feeds where feeds.id = posts.feed_id and posts.read = ? and feeds.id = ? order by feeds.category, feeds.name', false, params[:id]]
  end

  private

  def render_posts query
        posts_per_feeds = []
    current_feed = -1
    database[*query].each do |row|
      if row[:feed_id] != current_feed
        posts_per_feeds << [row[:feed_id]]
        current_feed = row[:feed_id]
      end
      parsed_post = Nokogiri::XML(row[:content])
      title = parsed_post.xpath('/entry/title')[0].content
      link = parsed_post.xpath('/entry/link[@type=\'text/html\']')[0]
      content = parsed_post.xpath('/entry/summary')[0].andand.content || parsed_post.xpath('/entry/content')[0].andand.content
      if link
        link = link['href']
      end
      posts_per_feeds.last << {:published_at => row[:published_at],
                               :title => title,
                               :link => link,
                               :id => row[:id],
                               :content => content}
    end
    halt 200, {'Content-Type' => 'application/json'}, posts_per_feeds.to_json
  end

end
