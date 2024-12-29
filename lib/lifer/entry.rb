require "digest/sha1"

class Lifer::Entry
  DEFAULT_DATE = Time.new(1900, 01, 01, 0, 0, 0, "+00:00")
  HTML_FILE_EXTENSIONS = ["html", "html.erb", "html.liquid"]
  MARKDOWN_FILE_EXTENSIONS = ["md"]
  FILE_EXTENSIONS =
    HTML_FILE_EXTENSIONS + MARKDOWN_FILE_EXTENSIONS

  attr_reader :file, :collection

  class << self
    attr_accessor :include_in_feeds
    attr_accessor :output_extension

    # The entrypoint for generating entry objects. We should never end up with
    # `Lifer::Entry` records: only subclasses.
    #
    # @param file [String] The absolute filename of an entry file.
    # @param collection [Lifer::Collection] The collection for the entry.
    # @return [Lifer::Entry::HTML, Lifer::Entry::Markdown]
    def generate(file:, collection:)
      error!(file) unless File.exist?(file)

      new_entry =
        case entry_type(file)
        when :html
          Lifer::Entry::HTML.new(file: file, collection: collection)
        when :markdown
          Lifer::Entry::Markdown.new(file: file, collection: collection)
        end

      Lifer.entry_manifest << new_entry if new_entry

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
    # @param supported_file_extensions [Array<String>] An array of file
    #   extensions to check agaainst.
    # @return [Boolean]
    def supported?(filename, supported_file_extensions = FILE_EXTENSIONS)
      supported_file_extensions.any? { |ext| filename.end_with? ext }
    end

    private

    # @private
    def entry_type(filename)
      case
      when supported?(filename, HTML_FILE_EXTENSIONS) then :html
      when supported?(filename, MARKDOWN_FILE_EXTENSIONS) then :markdown
      end
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

  self.include_in_feeds = false
  self.output_extension = nil
end

require_relative "entry/html"
require_relative "entry/markdown"
