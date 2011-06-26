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

        if !dst.nil?
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
            results.first
          end
        end
      end
    end

  end

end

# Fix for ruby 1.9.2
# https://github.com/flavorjones/loofah/pull/30
module Loofah
  module HTML5
    module Scrub
      class << self

        def scrub_attributes(node)
          node.attribute_nodes.each do |attr_node|
            attr_name = if attr_node.namespace
                          "#{attr_node.namespace.prefix}:#{attr_node.node_name}"
                        else
                          attr_node.node_name
                        end
            attr_node.remove unless HashedWhiteList::ALLOWED_ATTRIBUTES[attr_name]
            if HashedWhiteList::ATTR_VAL_IS_URI[attr_name]
              # this block lifted nearly verbatim from HTML5 sanitization
              val_unescaped = CGI.unescapeHTML(attr_node.value).gsub(/`|[\u0000-\u0020\u007F]+|[\uC280-\uC2A0]/, '').downcase
              if val_unescaped =~ /^[a-z0-9][-+.a-z0-9]*:/ and HashedWhiteList::ALLOWED_PROTOCOLS[val_unescaped.split(':')[0]].nil?
                attr_node.remove
              end
            end
            if HashedWhiteList::SVG_ATTR_VAL_ALLOWS_REF[attr_name]
              attr_node.value = attr_node.value.gsub(/url\s*\(\s*[^#\s][^)]+?\)/m, ' ') if attr_node.value
            end
            if HashedWhiteList::SVG_ALLOW_LOCAL_HREF[node.name] && attr_name == 'xlink:href' && attr_node.value =~ /^\s*[^#\s].*/m
              attr_node.remove
            end
          end
          if node.attributes['style']
            node['style'] = scrub_css(node.attributes['style'])
          end
        end
      end
    end
  end
end


class Tidal

  # Fetch all the feeds
  get '/fetch' do
    multi = Curl::Multi.new
    timestamp = Feed.order(:last_fetch.asc).first.last_fetch
    urls = Feed.collect { |f| f.feed_uri }
    urls.slice!(0, 10).each do |url|
      params = {
          :on_success => lambda { |u, f| feed_fetch_success(u, f) },
          :on_failure => lambda { |u, c, h, b| feed_fetch_failure(u, c, h, b) }}
      if timestamp
        params[:if_modified_since] = timestamp
      end
      Feedzirra::Feed.add_url_to_multi(multi, url, urls, {}, params)
    end
    multi.perform
    "OK"
  end

  private

  # When a fetch is successful
  # url: the fetched url
  # feed: the Feed object that has been fetched
  def feed_fetch_success url, feed
    begin
      f = Feed.filter(:feed_uri => url).first
      f.last_fetch = DateTime.now

      # the uri changed (redirection)
      if f.feed_uri != feed.feed_url
        f.feed_uri = feed.feed_url
      end

      now = DateTime.now
      # the date of the last post
      if feed.entries.first
        d = feed.entries.first.published ? parse_date(feed.entries.first.published) : now
        if (!f.last_post) || (d > f.last_post)
          f.last_post = d
        end
      end
      f.save

      # create the entries
      feed.entries.each do |entry|
        create_post(entry, f)
      end
    rescue Exception => e
      p e
    end
  end

  # Create a post from an entry.
  # entry: the feed Entry
  # feed: the Feed
  def create_post entry, feed
    entry_id = entry.id.encode('UTF-8')
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

      Post.create(:content => adapt_content((entry.content || entry.summary).andand.sanitize, feed.site_uri),
                  :title => adapt_content(entry.title.andand.sanitize, feed.site_uri),
                  :uri => entry.url,
                  :read => false,
                  :feed_id => feed.id,
                  :published_at => published_at,
                  :entry_id => entry_id)
    end
  end

  # When fetching a feed failed
  # url: the fetched url
  # response_code: the http response code
  # response_header: the response header
  # response_body: the response_body
  def feed_fetch_failure url, response_code, response_header, response_body
    Feed.filter(:feed_uri => url).update(:last_fetch => DateTime.now)
    if response_code != 304
      p "Error #{url} #{response_code} #{response_body}"
    end
  end

  # Fetch a unique feed
  def fetch_feed url
    multi = Curl::Multi.new
    urls = {}
    Feedzirra::Feed.add_url_to_multi(multi, url, urls, {}, {
        :on_success => lambda { |u, f| feed_fetch_success(u, f) },
        :on_failure => lambda { |u, c, h, b| feed_fetch_failure(u, c, h, b) }})
    multi.perform
    "OK"
  end

  # Adapt content for reading it in a website:
  # - remove the scripts tags and inline the noscript
  # - change the relative urls in image and links to absolute
  def adapt_content content, site_url
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

  def parse_date date
    begin
      DateTime.rfc2822(date)
    rescue ArgumentError
      begin
        DateTime.xmlschema(date)
      rescue ArgumentError
        DateTime.parse(date)
      end
    end
  end

end
