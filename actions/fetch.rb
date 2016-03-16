require 'addressable/uri'
require 'typhoeus'

# fetching the feeds

# Remove the itunes parser
Feedjira::Feed.feed_classes.delete_if { |c| c == Feedjira::Parser::ITunesRSS }

class Tidal

  # Fetch all the feeds
  get '/fetch' do
    # Delete old posts
    Post.filter('published_at < ?', DateTime.now - 20).delete

    hydra = Typhoeus::Hydra.new
    Feed.each do |feed|
      request = Typhoeus::Request.new(feed.feed_uri)
      request.on_complete do |response|
        if response.code == 200
          begin
            fetched_feed = Feedjira::Feed.parse(response.body)
            feed_fetch_success(feed, response.effective_url, fetched_feed)
          rescue Exception => e
            feed.last_fetch = DateTime.now
            feed.error_message = e.message
            feed.save
          end
        else
          feed.last_fetch = DateTime.now
          feed.error_message = "Code : #{response.code}\n#{response.body}"
          feed.save
        end
      end
      hydra.queue request
    end
    hydra.run
    'OK'
  end

  private

  # When a fetch is successful
  # @param feed [Feed] the feed object
  # @param feed_url [String] the feed url
  # @param fetched_feed [Feedjira::Feed] the Feed object that has been fetched
  def feed_fetch_success(feed, feed_url, fetched_feed)
    begin
      now = DateTime.now
      feed.last_fetch = now
      feed.error_message = nil
      feed.feed_uri = feed_url

      # the date of the last post
      if fetched_feed.entries.first && fetched_feed.entries.first.published
        last_post_date = fetched_feed.entries.first.published.to_datetime
        if (!feed.last_post) || (last_post_date > feed.last_post)
          feed.last_post = last_post_date
        end
      end
      feed.save

      # create the entries
      fetched_feed.entries.each do |entry|
        begin
          create_post(entry, feed)
        rescue Exception => e
          feed.error_message = e.backtrace.join("\n")
        end
      end

      feed.last_successful_fetch = now
    rescue Exception => e
      feed.error_message = e.backtrace.join("\n")
    ensure
      feed.save
    end
  end

  # Create a post from an entry.
  # entry: the feed Entry
  # feed: the Feed
  def create_post(entry, feed)
    if (entry_id = (entry.entry_id.andand.encode('UTF-8') || entry.url))
      if Post.filter(:entry_id => entry_id, :feed_id => feed.id).count == 0
        now = DateTime.now

        if entry.published
          published_at = entry.published.to_datetime

          # no old entries
          if (now - published_at).to_f > 7.0
            return
          end

          # publish date is too much in the future -> set it to now
          if (published_at - now).to_f > 1.0
            published_at = now
          end

        else
          published_at = now
        end
        DATABASE.transaction do
          Post.create(:content => adapt_content((entry.content || entry.summary).andand.encode('UTF-8').andand.sanitize, feed.site_uri),
                      :title => adapt_content(entry.title.andand.encode('UTF-8').andand.sanitize, feed.site_uri),
                      :uri => entry.url,
                      :read => false,
                      :feed_id => feed.id,
                      :published_at => published_at,
                      :entry_id => entry_id)
        end
      end
    end
  end

  # Adapt content for reading it in a website:
  # - remove the scripts tags and inline the noscript
  # - change the relative urls in image and links to absolute
  def adapt_content(content, site_url)
    if content

      parsed_content = Nokogiri::HTML.fragment(content)

      # remove scripts
      parsed_content.css('script').each do |node|
        node.unlink
      end

      # inline noscripts contents
      parsed_content.css('noscript').each do |node|
        node.elements.each do |sub|
          node.add_next_sibling sub
        end
        node.unlink
      end

      uri = Addressable::URI.parse(site_url)

      # make links absolutes
      parsed_content.search('img[@src],frame[@src],embed[@src]').each do |i|
        i['src'] = uri.join(i['src']).normalize.to_s
      end

      parsed_content.search('a[@href]').each do |a|
        # not for internal links
        unless a['href'].index('#') == 0
          a['href'] = uri.join(a['href']).normalize.to_s
        end
      end

      parsed_content.to_s
    end
  end

end
