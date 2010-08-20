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
      Nokogiri::XML(request.body.read).css('entry').each do |entry|
        published_at = DateTime.now
        entry.css('published').each do |published|
          published_at = DateTime.parse(published.content)
        end

        # no old entries
        if ((DateTime.now - published_at) < 7)
          entry_id = entry.css('id')[0].andand.content

          # protection agains duplicates
          if (entry_id.blank? || (Post.where(:entry_id => entry_id, :feed_id => params[:id]).count == 0))
            Post.create(:content => entry.serialize,
                        :read => false,
                        :feed_id => params[:id],
                        :published_at => published_at,
                        :entry_id => entry_id)
          end
        end
      end
    end
    halt 200, 'OK'
  end

end
