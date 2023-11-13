require "rss"

# Link to RSS 2.0 specification with RSSBoard editorial corrections:
#
#   https://www.rssboard.org/rss-specification
#
class Lifer::Builder::RSS
  DEFAULT_FEED_FILENAME = "feed.xml"

  class << self
    def execute(root:)
      Dir.chdir Lifer.output_directory do
        new(root: root).execute
      end
    end
  end

  def execute
    collections_with_feeds.each do |collection|
      new_feed =
        rss_feed_for(collection) do |current_feed|
          collection.entries.each { |entry| rss_entry current_feed, entry }
        end

      output_filename =
        File.join Dir.pwd, Lifer.setting(:feed, :uri, collection: collection)

      File.open output_filename, "w" do |file|
        file.puts new_feed.to_feed
      end
    end
  end

  private

  attr_reader :collections_with_feeds, :root

  def initialize(root:)
    @collections_with_feeds =
      Lifer.collections.select { |collection| collection.setting(:feed, :uri) }
    @root = root
  end

  def rss_entry(rss_feed, lifer_entry)
    rss_feed.maker.items.new_item do |rss_feed_item|
      if (authors = lifer_entry.authors).any?
        rss_feed_item.author = authors.join(", ")
      end
      rss_feed_item.id = lifer_entry.permalink
      rss_feed_item.link = lifer_entry.permalink
      rss_feed_item.title = lifer_entry.title
      rss_feed_item.summary = lifer_entry.summary
      rss_feed_item.updated = Time.now.to_s
    end
  end

  def rss_feed_for(collection, &block)
    feed_object = nil

    ::RSS::Maker.make "rss2.0" do |feed|
      feed.channel.description =
        Lifer.setting(:description, collection: collection) ||
          Lifer.setting(:site_title, collection: collection)

      feed.channel.language = Lifer.setting(:language, collection: collection)

      feed.channel.lastBuildDate = Time.now.to_s

      feed.channel.link = "%s/%s" % [
        Lifer.setting(:global, :host),
        Lifer.setting(:feed, :uri, collection: collection)
      ]

      feed.channel.managingEditor =
        Lifer.setting(:site_default_author, collection: collection)

      feed.channel.title = Lifer.setting(:title, collection: collection)

      feed.channel.webMaster =
        Lifer.setting(:site_default_author, collection: collection)

      yield feed

      feed_object = feed
    end
    feed_object
  end
end
