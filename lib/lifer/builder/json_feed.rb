require "fileutils"

class Lifer::Builder
  # This builds JSON feed compliant with the JSON Feed 1.1
  # specification[1]. Note that we don't currently support *all* of the features
  # of JSON Feed, but it shouldn't be too hard to add them.
  #
  # The JSON Feed builder can be configured in a number of ways:
  #
  # 1. Boolean
  #
  #    Simply set `json_feed: true` or `json_feed: false` to enable or disable
  #    a feed for a collection. If `true`, a JSON feed will be build to
  #    `/name-of-collection.json` at the root of the Lifer output directory.
  #
  # 2. Simple
  #
  #    Simply set `json_feed: name-of-output-file.json` to specify the name of
  #    the output JSON Feed file.
  #
  # 3. Fine-grained
  #
  #    Provide an object under `json_feed:` for more fine-grained control over
  #    configuration. The following sub-settings are supported:
  #
  #    - `authors:` A list of authors to fall back to if an entry does not
  #      have its own authors data. Each author can include the following fields:
  #        - `name:` The author's name.
  #        - `url:` A URL that represents the author.
  #        - `avatar:` The URL to an avatar that represents the author.
  #    - `content_format:` The format of the feed entries for the entire feed.
  #      Either `html` or `text`. (Default: `html`.)
  #    - `count:` - The limit of JSON Feed items that should be included in the
  #      output document. Leave unset or set to `0` to include all entries.
  #    - `expired:` Set the expired flag on the feed to broadcast whether
  #      the feed will continue to be updated.
  #    - `home_page_url:` A URL that represents the home page of the current
  #      feed.
  #    - `url:` The path to the filename of the output JSON Feed file.
  #
  # [1] https://www.jsonfeed.org/version/1.1/
  #
  class JSONFeed < Lifer::Builder
    # As of this writing, we support the latest version of the JSON Feed
    # specification.
    #
    JSON_FEED_VERSION = "1.1"

    self.name = :json_feed
    self.settings = [
      json_feed: [
        {authors: [:name, :url, :avatar]},
        :content_format,
        :count,
        :expired,
        :home_page_url,
        :url
      ]
    ]

    class << self
      # Traverses and renders a JSON Feed for each JSON Feed-enabled, feedable
      # collection in the configured output directory for the Lifer project.
      #
      # @param root [String] The Lifer root.
      # @return [void]
      def execute(root:)
        Dir.chdir Lifer.output_directory do
          new(root:).execute
        end
      end
    end

    # Traverses and renders a JSON Feed for JSON Feed-enabled feedable
    # collections.
    #
    # @return [void]
    def execute
      collections_with_feeds.each do |collection|
        next unless (filename = output_filename(collection))

        FileUtils.mkdir_p File.dirname(filename)

        File.open filename, "w" do |file|
          file.puts(
            json_feed_for(collection) do |current_feed|
              max_index = max_feed_items(collection) - 1

              collection.entries
                .select { |entry| entry.feedable? }[0..max_index]
                .each { |entry| json_feed_entry(current_feed, entry, collection) }
            end
          )
        end
      end
    end

    private

    attr_reader :collections_with_feeds, :root

    def initialize(root:)
      @collections_with_feeds =
        Lifer.collections.select { |collection| collection.setting :json_feed }
      @root = root
    end

    # Builds an entry in the JSON Feed given the current JSON Feed being
    # built, a Lifer entry, and a Lifer collection.
    #
    # @param feed_object [Hash] JSON Feed currently being built.
    # @param lifer_entry [Lifer::Entry] The Lifer entry to build an entry for.
    # @param lifer_collection [Lifer::Collection] The Lifer collection for
    #   the entry. This provides additional context that may be required
    #   for some parts of JSON Feed entry schema.
    # @return [void] The entry is added to the JSON Feed as a side effect
    #   by the end of this procedure.
    def json_feed_entry(feed_object, lifer_entry, lifer_collection)
      feed_item_object = {
        id: lifer_entry.permalink,
        url: lifer_entry.permalink,
        external_url: lifer_entry.frontmatter[:external_url],
        title: lifer_entry.title,
        summary: lifer_entry.summary,
        image: lifer_entry.assets.detect { |asset|
          asset.match?(
            url: lifer_entry.frontmatter[:image] ||
              lifer_entry.frontmatter[:images]&.first
          )
        }&.url,
        banner_image: lifer_entry.assets.detect { |asset|
          asset.match? url: lifer_entry.frontmatter[:banner_image]
        }&.url,
        date_published: lifer_entry.published_at,
        date_modified: lifer_entry.updated_at(fallback: lifer_entry.published_at),
        tags: lifer_entry.tags,
        language: lifer_collection.setting(:language)
      }

      feed_content_format =
        lifer_collection.setting(:json_feed, :content_format)&.to_sym || :html
      case feed_content_format
      when :html
        feed_item_object[:content_html] = lifer_entry.to_html
      when :text
        # Currently, `Entry#to_html` is just the name of the method we use
        # to get the entry content, regardless of whether the entry output is
        # HTML or not.
        feed_item_object[:content_text] = lifer_entry.to_html
      end

      if (authors = lifer_entry.authors).any?
        feed_item_object[:authors] = authors.map { |author|
          {
            name: author.name,
            avatar: author.avatar,
            url: author.url
          }.reject { |_key, value| value.nil? }
        }
      end

      feed_object[:items] << feed_item_object
    end

    # Provides the entire feed object for serialization.
    #
    # Note that we don't currently support JSON Feed 1.1 *exhaustively*. For
    # example, we don't currently support pagniation or hubs. Here's a list
    # of root-level 1.1 fields we do not currently support:
    #
    #   - authors
    #   - favicon
    #   - hubs
    #   - icon
    #   - next_url
    #   - user_comment
    #
    # @param collection [Lifer::Collection] The current Lifer collection for
    #   metadata context.
    # @return [String] The JSON representation of the JSON Feed.
    def json_feed_for(collection, &block)
      feed_object = {
        version: JSON_FEED_VERSION,
        title: collection.setting(:title),
        description: collection.setting(:description) || collection.setting(:site_title),
        expired: collection.setting(:json_feed, :expired, strict: true),
        feed_url: collection.setting(:json_feed, :url, strict: true),
        home_page_url: collection.setting(:json_feed, :home_page_url, strict: true),
        language: collection.setting(:language),
        items: []
      }
      feed_object = feed_object.reject { |_key, value| value.nil? }

      yield feed_object

      feed_object.to_json
    end

    def max_feed_items(collection) = collection.setting(:json_feed, :count) || 0

    def output_filename(collection)
      strict = !collection.root?

      case collection.setting(:json_feed, strict:)
      when FalseClass, NilClass then nil
      when TrueClass then File.join(Dir.pwd, "#{collection.name}.json")
      when Hash
        File.join Dir.pwd, collection.setting(:json_feed, :url, strict:)
      when String
        File.join Dir.pwd, collection.setting(:json_feed, strict:)
      end
    end
  end
end
