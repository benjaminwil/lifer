require "rss"

# Builds a simple RSS 2.0[1] feed using the Ruby standard library's RSS
# features.
#
# [1]: https://www.rssboard.org/rss-specification
#
class Lifer::Builder::RSS < Lifer::Builder
  self.name = :rss
  self.settings = [:rss]

  class << self
    # Traverses and renders an RSS feed for each feedable collection in the
    # configured output directory for the Lifer project.
    #
    # @param root [String] The Lifer root.
    # @return [void]
    def execute(root:)
      Dir.chdir Lifer.output_directory do
        new(root: root).execute
      end
    end
  end

  # Traverses and renders an RSS feed for feedable collection.
  #
  # @return [void]
  def execute
    collections_with_feeds.each do |collection|
      next unless (filename = output_filename(collection))

      File.open filename, "w" do |file|
        file.puts(
          rss_feed_for(collection) do |current_feed|
            collection.entries
              .select { |entry| entry.feedable? }
              .each { |entry| rss_entry current_feed, entry }
          end.to_feed
        )
      end
    end
  end

  private

  attr_reader :collections_with_feeds, :root

  def initialize(root:)
    @collections_with_feeds =
      Lifer.collections.select { |collection| collection.setting :rss }
    @root = root
  end

  def output_filename(collection)
    strict_mode = !collection.root?

    case collection.setting(:rss, strict: strict_mode)
    when FalseClass, NilClass then nil
    when TrueClass then File.join(Dir.pwd, "#{collection.name}.xml")
    else
      File.join Dir.pwd, collection.setting(:rss, strict: strict_mode)
    end
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
      rss_feed_item.content_encoded = lifer_entry.to_html
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
        Lifer.setting(:rss, collection: collection)
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
