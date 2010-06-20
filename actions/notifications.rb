# The action called by superfeeder
class Tidal

  # subscription confirmation
  get '/callback/:id' do
    is_subscribing = (params['hub.mode'] == 'subscribe')
    Feed.where(:id => params[:id]).update(:subscription_validated => is_subscribing)
    log "Callback received, answering [#{params['hub.challenge']}]"
    halt 200, params['hub.challenge']
  end

  # receive the new items
  post '/callback/:id' do
    if Feed.where(:id => params[:id]).update(:last_notification => DateTime.now) == 1
      content = request.body.read
      File.open("feed_#{params[:id]}.xml", 'w') { |f| f.write(content) }
      Nokogiri::XML(content).css('entry').each do |entry|
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
