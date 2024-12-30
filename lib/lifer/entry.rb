require "digest/sha1"

# An entry is a Lifer file that will be built into the output directory.
# There are more than one subclass of entry: Markdown entries are the most
# traditional, but HTML and text files are also very valid entries.
#
# This class provides a baseline of the functionality that all entry subclasses
# should implement. It also provides the entry generator for *all* entry
# subclasses.
#
# FIXME: Markdown entries are able to provide metadata via frontmatter, but
#   other entry types do not currently support frontmatter. Should they? Or is
#   there some nicer way to provide entry metadata for non-Markdown files in
#   2024?
#
class Lifer::Entry
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

  attr_reader :file, :collection

  class << self
    # The entrypoint for generating entry objects. We should never end up with
    # `Lifer::Entry` records: only subclasses.
    #
    # @param file [String] The absolute filename of an entry file.
    # @param collection [Lifer::Collection] The collection for the entry.
    # @return [Lifer::Entry::HTML, Lifer::Entry::Markdown]
    def generate(file:, collection:)
      error!(file) unless File.exist?(file)

      if (new_entry = subclass_for(file)&.new(file:, collection:))
        Lifer.entry_manifest << new_entry
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

  # When a new Markdown entry is initialized we expect the file to already
  # exist, and we expect to know which `Lifer::Collection` it belongs to.
  #
  # @param file [String] An absolute path to a file.
  # @param collection [Lifer::Collection] A collection.
  # @return [Lifer::Entry]
  def initialize(file:, collection:)
    @file = Pathname file
    @collection = collection
  end

  def feedable?
    if (setting = self.class.include_in_feeds).nil?
      raise NotImplementedError,
        I18n.t("entry.feedable_error", entry_class: self.class)
    end

    setting
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

  def title
    raise NotImplementedError, I18n.t("shared.not_implemented_method")
  end

  def to_html
    raise NotImplementedError, I18n.t("shared.not_implemented_method")
  end
end

