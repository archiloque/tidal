# The action called by superfeeder
class Tidal

  # subscription confirmation
  get '/callback/:id' do
    halt 200, params['hub.challenge']
  end

  # receive the new items
  post '/callback/:id' do
    if Feed.where(:id => params[:id]).update(:last_notification => DateTime.now) == 1
      Nokogiri::XML(request.body.read).css('entry').each do |entry|
        published_at = DateTime.now
        entry.css('published').each do |published|
          published_at = DateTime.parse(published.content)
        end
        Post.create(:content => entry.serialize,
                    :read => false,
                    :feed_id => params[:id],
                    :published_at => published_at)
      end
    end
    halt 200, 'OK'
  end

end
