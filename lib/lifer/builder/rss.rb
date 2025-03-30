require "fileutils"
require "rss"

# FIXME: Can this feed builder just take a type for Atom feeds instead of us
#  creating a separate builder?

# Builds a simple, UTF-8, RSS 2.0[1] feed using the Ruby standard library's RSS
# features.
#
# The features of the generated feed attempt to follow the recommendations for
# RSS feeds specified by RSS Board[2].
#
# The RSS builder can be configured in a number of ways:
#
# 1. Boolean
#
#    Simply set `rss: true` or `rss: false` to enable or disable a feed for a
#    collection. If `true`, an RSS feed will be built to `name-of-collection.xml`
#
# 2. Simple
#
#    Simply set `rss: name-of-output-file.xml` to specify the name of the
#    output XML file.
#
# 3. Fine-grained
#
#    Provide an object under `rss:` for more fine-grained control over
#    configuration. The following sub-settings are supported:
#
#    - `count:` - The limit of RSS feed items that should be included in the
#      output document. Leave unset or set to `0` to include all entries.
#    - `format:` - The RSS format to build with. Either `rss` or `atom` are
#      supported. `rss` is the default format.
#    - `managing_editor:` - the contents of the `<managingEditor>` node of the
#      RSS document. When unset, Lifer builds a valid `<managingEditor>` value
#      using the collection or root `author` value and a null email address to
#      ensure that RSS feed validators are satisfied.
#    - `url:` -  the path to the filename of the output XML file.
#
# [1]: https://www.rssboard.org/rss-specification
# [2]: https://www.rssboard.org/rss-profile
#
class Lifer::Builder::RSS < Lifer::Builder
  # Because Lifer has no reason to have record of anyone's email address, we
  # provide a non-email address so a <managingEditor> can be set and validated by
  # RSS validators.
  #
  # Note that `.invalid` is a special-use TLD[1] that helps us indicate that the
  # email address is definitely not real.
  #
  # [1]: https://datatracker.ietf.org/doc/html/rfc6761
  #
  DEFAULT_MANAGING_EDITOR_EMAIL = "editor@null.invalid"

  # All of the available formats that this builder can build. Where the keys
  # are formats accepted as input in configuration files and the values are
  # the formats that the RSS builder will output.
  #
  FORMATS = {atom: "atom", rss: "rss2.0"}

  # The default format for this RSS feed builder. Where the key is the format
  # accepted as input in configuration files and the value is the format that
  # the RSS builder will output.

  # The name of the format type, as needed by `RSS::Maker`, used by default by
  # this feed builder.
  #
  DEFAULT_MAKER_FORMAT_NAME = FORMATS[:rss]

  self.name = :rss
  self.settings = [
    rss: [
      :count,
      :format,
      :managing_editor,
      :url
    ]
  ]

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

  def feed_format(collection)
    format = Lifer.setting(:rss, :format, collection:)&.to_sym

    return FORMATS[format] if FORMATS.keys.include? format

    DEFAULT_MAKER_FORMAT_NAME
  end

  # Traverses and renders an RSS feed for feedable collection.
  #
  # @return [void]
  def execute
    Lifer::Utilities.parallelized collections_with_feeds do |collection|
      next unless (filename = output_filename(collection))

      FileUtils.mkdir_p File.dirname(filename)

      File.open filename, "w" do |file|
        file.puts(
          rss_feed_for(collection) do |current_feed|
            max_index = max_feed_items(collection) - 1

            collection.entries
              .select { |entry| entry.feedable? }[0..max_index]
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

  # According to the RSS Board, the recommended format for the
  # `<managingEditor>` feed data is
  #
  #     editor@example.com (Editor Name)
  #
  # Unfortunately, Lifer has no reason to have record of the editor's email
  # address except for in RSS feeds, so if an `rss.managing_editor` is not
  # configured we'll do our best to at provide information managing editor's
  # that RSS feed validators are satisified with using other site configuration
  # containing an author's name. Example output:
  #
  #     editor@null.invalid (Configured Author Name)
  #
  # @param collection [Lifer::Collection]
  # @return [String] The managing editor string for a `<managingEditor>` RSS
  #   feed field.
  def managing_editor(collection)
    editor = collection.setting(:rss, :managing_editor)

    return editor if editor

    "%s (%s)" % [
      DEFAULT_MANAGING_EDITOR_EMAIL,
      Lifer.setting(:author, collection: collection)
    ]
  end

  # The amount of feed items to output to the RSS file. If set to 0, there is no
  # max limit of feed items.
  #
  # @param collection [Lifer::Collection]
  # @return [Integer]
  def max_feed_items(collection) = Lifer.setting(:rss, :count, collection:) || 0

  def output_filename(collection)
    strict = !collection.root?

    case collection.setting(:rss, strict:)
    when FalseClass, NilClass then nil
    when TrueClass
      File.join Dir.pwd, "#{collection.name}.xml"
    when Hash
      File.join Dir.pwd, collection.setting(:rss, :url, strict:)
    when String
      File.join Dir.pwd, collection.setting(:rss, strict:)
    end
  end

  # @fixme Using the W3C feed validation checker[1], I found that RSS and Atom
  #   feed items generated by Lifer are missing some recommended functionality.
  #
  #   RSS reports:
  #
  #   > This feed is valid, but interoperability with the widest range of feed
  #   > readers could be improved by implementing the following recommendations.
  #   >
  #   > An item should not include both pubDate and dc:date
  #   > (https://validator.w3.org/feed/docs/warning/DuplicateItemSemantics.html)
  #   >
  #   > item should contain a guid element
  #   > (https://validator.w3.org/feed/docs/warning/MissingGuid.html)
  #   >
  #   > content:encoded should not contain relative URL references
  #   > (https://validator.w3.org/feed/docs/warning/ContainsRelRef.html)
  #
  #   Regarding the `<content:encoded>` field... this seems to be more closely
  #   related to our Markdown parser implementation than the RSS feed generation
  #   itself.
  #
  #   Atom reports:
  #
  #   > Two or more entries with the same value for <atom:updated>
  #   > (https://validator.w3.org/feed/docs/warning/DuplicateUpdated.html)
  #   >
  #   > Missing <atom:link> with rel="self".
  #   > (https://validator.w3.org/feed/docs/warning/MissingSelf.html)
  #
  #   [1]: https://validator.w3.org/feed/check.cgi
  #
  def rss_entry(rss_feed, lifer_entry)
    rss_feed.maker.items.new_item do |rss_feed_item|
      if (authors = lifer_entry.authors).any?
        rss_feed_item.author = authors.join(", ")
      end
      rss_feed_item.id = lifer_entry.permalink
      rss_feed_item.link = lifer_entry.permalink
      rss_feed_item.title = lifer_entry.title
      rss_feed_item.summary = lifer_entry.summary

      if feed_format(lifer_entry.collection) == "atom"
        rss_feed_item.content.content = lifer_entry.to_html
        rss_feed_item.published = lifer_entry.published_at

        # Note: RSS does not provide a standard way to share last updated
        # timestamps at all, while Atom does. This is the reason there is no
        # equivalent call in the condition for RSS feeds.
        #
        rss_feed_item.updated =
          lifer_entry.updated_at(fallback: lifer_entry.published_at)
      else
        rss_feed_item.content_encoded = lifer_entry.to_html
        rss_feed_item.pubDate = lifer_entry.published_at.to_time.rfc2822
      end
    end
  end

  # @fixme Using the W3C feed validation checker[1], I found that RSS feeds
  #   generated by Lifer are missing some recommended functionality. Reports:
  #
  #   > Missing atom:link with rel="self"
  #   > (https://validator.w3.org/feed/docs/warning/MissingAtomSelfLink.html)
  #
  #   [1]: https://validator.w3.org/feed/check.cgi
  #
  def rss_feed_for(collection, &block)
    feed_object = nil

    ::RSS::Maker.make feed_format(collection) do |feed|
      feed.channel.description =
        Lifer.setting(:description, collection: collection) ||
          Lifer.setting(:site_title, collection: collection)

      feed.channel.language = Lifer.setting(:language, collection: collection)

      channel_link = "%s/%s" % [
        Lifer.setting(:global, :host),
        Lifer.setting(:rss, :url, collection:)
      ]

      # The W3C Atom validator claims that the <id> should be a "canonicalized"
      # URL with a slash at the end.
      #
      channel_link = channel_link + "/" unless channel_link.end_with?("/")

      feed.channel.lastBuildDate = Time.now.to_s
      feed.channel.link = channel_link

      # Additional channel fields for Atom format feeds.
      #
      if feed_format(collection) == "atom"
        feed.channel.author = Lifer.setting(:author, collection: collection)
        feed.channel.id = channel_link
        feed.channel.updated = Time.now.to_s
      end

      feed.channel.managingEditor = managing_editor(collection)
      feed.channel.title = Lifer.setting(:title, collection: collection)
      feed.channel.webMaster =
        Lifer.setting(:site_default_author, collection: collection)

      yield feed

      feed_object = feed
    end
    feed_object
  end
end
