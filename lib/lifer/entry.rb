require "digest/sha1"

module Lifer
  # An entry is a Lifer file that will be built into the output directory.
  # There are more than one subclass of entry: Markdown entries are the most
  # traditional, but HTML and text files are also very valid entries.
  #
  # This class provides a baseline of the functionality that all entry
  # subclasses should implement. It also provides the entry generator for
  # *all* entry subclasses.
  #
  # @fixme Markdown entries are able to provide metadata via frontmatter, but
  #   other entry types do not currently support frontmatter. Should they? Or is
  #   there some nicer way to provide entry metadata for non-Markdown files in
  #   2024?
  #
  class Entry
    class << self
      attr_accessor :include_in_feeds
      attr_accessor :input_extensions
      attr_accessor :output_extension
    end

    self.include_in_feeds = false
    self.input_extensions = []
    self.output_extension = nil

    require_relative "entry/html"
    require_relative "entry/markdown"
    require_relative "entry/txt"

    # We provide a default date for entries that have no date and entry types that
    # otherwise could not have a date due to no real way of getting that metadata.
    #
    DEFAULT_DATE = Time.new(1900, 01, 01, 0, 0, 0, "+00:00")

    # If a filename contains a date, we should expect it to be in the following
    # format.
    #
    FILENAME_DATE_FORMAT = /^(\d{4}-\d{1,2}-\d{1,2})-/

    # We expect frontmatter to be provided in the following format.
    #
    FRONTMATTER_REGEX = /^---\n(.*)---\n/m

    # If tags are represented in YAML frontmatter as a string, they're split on
    # commas and/or spaces.
    #
    TAG_DELIMITER_REGEX = /[,\s]+/

    # We truncate anything that needs to be truncated (summaries, meta
    # descriptions) at the following character count.
    #
    TRUNCATION_THRESHOLD = 120

    attr_reader :file, :collection

    class << self
      # The entrypoint for generating entry objects. We should never end up with
      # `Lifer::Entry` records: only subclasses.
      #
      # @param file [String] The absolute filename of an entry file.
      # @param collection [Lifer::Collection] The collection for the entry.
      # @return [Lifer::Entry] An entry.
      def generate(file:, collection:)
        error!(file) unless File.exist?(file)

        if (new_entry = subclass_for(file)&.new(file:, collection:))
          Lifer.entry_manifest << new_entry
          new_entry.tags
        end

        new_entry
      end

      # Whenever an entry is generated it should be added to the entry manifest.
      # This lets us get a list of all generated entries.
      #
      # @return [Array<Lifer::Entry>] A list of all entries that currently exist.
      def manifest
        return Lifer.entry_manifest if self == Lifer::Entry

        Lifer.entry_manifest.select { |entry| entry.class == self }
      end

      # Checks whether the given filename is supported entry type (using only its
      # file extension).
      #
      # @param filename [String] The absolute filename to an entry.
      # @param file_extensions [Array<String>] An array of file extensions to
      #   check against.
      # @return [Boolean]
      def supported?(filename, file_extensions= supported_file_extensions)
        file_extensions.any? { |ext| filename.end_with? ext }
      end

      private

      def supported_file_extensions
        @supported_file_extensions ||= subclasses.flat_map(&:input_extensions)
      end

      # @private
      # Retrieve the entry subclass based on the current filename.
      #
      # @param filename [String] The current entry's filename.
      # @return [Class] The entry subclass for the current entry.
      def subclass_for(filename)
        Lifer::Entry.subclasses.detect { |klass|
          klass.input_extensions.any? { |ext| filename.end_with? ext }
        }
      end

      # @private
      def error!(file)
        raise StandardError, I18n.t("entry.not_found", file:)
      end
    end

    # When a new entry is initialized we expect the file to already exist, and
    # we expect to know which `Lifer::Collection` it belongs to.
    #
    # @param file [String] An absolute path to a file.
    # @param collection [Lifer::Collection] A collection.
    # @return [Lifer::Entry]
    def initialize(file:, collection:)
      @file = Pathname file
      @collection = collection
    end

    # Given the entry's frontmatter, we should be able to get a list of authors.
    # We always prefer authors (as opposed to a singular author) because it makes
    # handling both cases easier in the long run.
    #
    # The return value here is likely an author's name. Whether that's a full
    # name, a first name, or a handle is up to the end user.
    #
    # @return [Array<String>] An array of authors's names.
    def authors
      Array(frontmatter[:author] || frontmatter[:authors]).compact
    end

    # This method returns the full text of the entry, only removing the
    # frontmatter. It should not parse anything other than frontmatter.
    #
    # @return [String] The body of the entry.
    def body
      return full_text.strip unless frontmatter?

      full_text.gsub(FRONTMATTER_REGEX, "").strip
    end

    def feedable?
      if (setting = self.class.include_in_feeds).nil?
        raise NotImplementedError,
          I18n.t("entry.feedable_error", entry_class: self.class)
      end

      setting
    end

    # Frontmatter is a widely supported YAML metadata block found at the top of
    # text--often Markdown--files. We attempt to parse all entries for
    # frontmatter.
    #
    # @return [Hash] A hash representation of the entry frontmatter.
    def frontmatter
      return {} unless frontmatter?

      Lifer::Utilities.symbolize_keys(
        YAML.load(full_text[FRONTMATTER_REGEX, 1], permitted_classes: [Time])
      )
    end

    # The full text of the entry.
    #
    # @return [String]
    def full_text
      @full_text ||= File.readlines(file).join if file
    end

    # Using the current Lifer configuration, we can calculate the expected
    # permalink for the entry. For example:
    #
    #    https://example.com/index.html
    #    https://example.com/blog/my-trip-to-toronto.html
    #
    # This would be useful for indexes and feeds and so on.
    #
    # @return [String] A permalink to the current entry.
    def permalink(host: Lifer.setting(:global, :host))
      cached_permalink_variable =
        "@entry_permalink_" + Digest::SHA1.hexdigest(host)

      instance_variable_get(cached_permalink_variable) ||
        instance_variable_set(
          cached_permalink_variable,
          File.join(
            host,
            Lifer::URIStrategy.find(collection.setting :uri_strategy)
              .new(root: Lifer.root)
              .output_file(self)
          )
        )
    end

    # The expected, absolute URI path to the entry. For example:
    #
    #    /index.html
    #    /blog/my-trip-to-toronto.html
    #
    # @return [String] The absolute URI path to the entry.
    def path = permalink(host: "/")

    # The entry's publication date. The published date can be inferred in a few
    # ways. The priority is:
    #
    #    1. the frontmatter's `published_at` field
    #    2. the frontmatter's `published` field
    #    3. the frontamtter's `date` field
    #    4. The date in the filename.
    #
    # Since text files would only store dates as simple strings, it's nice to
    # attempt to convert those into Ruby date or datetime objects.
    #
    # @return [Time] A Ruby representation of the date and time provided by the
    #   entry frontmatter or filename.
    def published_at
      date_for frontmatter[:published_at],
        frontmatter[:published],
        frontmatter[:date],
        filename_date,
        missing_metadata_translation_key: "entry.no_published_at_metadata"
    end

    # If given a summary in the frontmatter of the entry, we can use this to
    # provide a summary.
    #
    # Since subclasses may have more sophisticated access to the document, they
    # may override this method with their own distinct implementations.
    ##
    # @return [String] A summary of the entry.
    def summary
      return frontmatter[:summary] if frontmatter[:summary]
    end

    # Locates and returns all tags defined in the entry.
    #
    # @return [Array<Lifer::Tag>] The entry's tags.
    def tags
      @tags ||= candidate_tag_names
        .map { Lifer::Tag.build_or_update(name: _1, entries: [self]) }
    end

    # Returns the title of the entry. Every entry subclass must implement this
    # method so that builders have access to *some* kind of title for each entry.
    #
    # @return [String]
    def title
      raise NotImplementedError, I18n.t("shared.not_implemented_method")
    end

    def to_html
      raise NotImplementedError, I18n.t("shared.not_implemented_method")
    end

    private

    # It is conventional for users to use spaces or commas to delimit tags in
    # other systems, so let's support that. But let's also support YAML-style
    # arrays.
    #
    # @return [Array<String>] An array of candidate tag names.
    def candidate_tag_names
      case frontmatter[:tags]
      when Array then frontmatter[:tags].map(&:to_s)
      when String then frontmatter[:tags].split(TAG_DELIMITER_REGEX)
      else []
      end.uniq
    end

    def date_for(*candidate_date_fields, missing_metadata_translation_key:)
      date_data = candidate_date_fields.detect(&:itself)

      case date_data
      when Time then date_data
      when String then DateTime.parse(date_data).to_time
      else
        Lifer::Message.log(missing_metadata_translation_key, filename: file)
        Lifer::Entry::DEFAULT_DATE
      end
    rescue ArgumentError => error
      Lifer::Message.error("entry.date_error", filename: file, error:)
      Lifer::Entry::DEFAULT_DATE
    end

    def filename_date
      return unless file && File.basename(file).match?(FILENAME_DATE_FORMAT)

      File.basename(file).match(FILENAME_DATE_FORMAT)[1]
    end

    def frontmatter? = (full_text && full_text.match?(FRONTMATTER_REGEX))
  end
end
