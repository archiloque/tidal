require 'addressable/uri'

# fetching the feeds

# Don't care about ambiguous timezones
module TZInfo
  class Timezone
    def period_for_local(local, dst = nil)
      results = periods_for_local(local)

      if results.empty?
        raise PeriodNotFound
      elsif results.size < 2
        results.first
      else
        # ambiguous result try to resolve

        if dst
          matches = results.find_all { |period| period.dst? == dst }
          results = matches if !matches.empty?
        end

        if results.size < 2
          results.first
        else
          # still ambiguous, try the block

          if block_given?
            results = yield results
          end

          if results.is_a?(TimezonePeriod)
            results
          else
            # hack is here
            results.first
          end
        end
      end
    end

  end

end

# Remove the itunes parser
Feedjira::Feed.feed_classes.delete_if { |c| c == Feedjira::Parser::ITunesRSS }

class Tidal

  # Fetch all the feeds
  get '/fetch' do
    # Delete old posts
    Post.filter('published_at < ?', DateTime.now - 20).delete
    Feed.each do |feed|
      fetch_feed(feed)
    end
    'OK'
  end

  private

  # When a fetch is successful
  # url: the fetched url
  # feed: the Feed object that has been fetched
  def feed_fetch_success(url, fetched_feed)
    begin
      f = Feed.filter(:feed_uri => url).first
      now = DateTime.now
      f.last_fetch = now
      f.error_message = nil

      # the uri changed (redirection)
      if f.feed_uri != fetched_feed.feed_url
        f.feed_uri = fetched_feed.feed_url
      end

      # the date of the last post
      if fetched_feed.entries.first
        d = fetched_feed.entries.first.published ? parse_date(fetched_feed.entries.first.published) : now
        if (!f.last_post) || (d > f.last_post)
          f.last_post = d
        end
      end
      f.save

      # create the entries
      fetched_feed.entries.each do |entry|
        begin
          create_post(entry, f)
        rescue Exception => e
          f.error_message = e.backtrace.join("\n")
        end
      end

      f.last_successful_fetch = now
    rescue Exception => e
      f.error_message = e.backtrace.join("\n")
    ensure
      f.save
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
          published_at = parse_date(entry.published)

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

  # Fetch a unique feed
  def fetch_feed(feed)
    begin
      fetched_feed = Feedjira::Feed.fetch_and_parse(feed.feed_uri)
      feed_fetch_success(feed.feed_uri, fetched_feed)
    rescue Exception => e
      feed.last_fetch = DateTime.now
      feed.error_message = e.message
      feed.save
    end
    'OK'
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

  def parse_date(date)
    if date
      date.to_datetime
    else
      DateTime.now
    end
  end

end
