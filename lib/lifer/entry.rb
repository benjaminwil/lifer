class Lifer::Entry
  HTML_FILE_EXTENSIONS = ["html", "html.erb"]
  MARKDOWN_FILE_EXTENSIONS = ["md"]
  FILE_EXTENSIONS =
    HTML_FILE_EXTENSIONS + MARKDOWN_FILE_EXTENSIONS

  attr_reader :file, :collection

  class << self
    attr_accessor :include_in_feeds

    # The entrypoint for generating entry objects. We should never end up with
    # `Lifer::Entry` records: only subclasses.
    #
    # @param file [String] The absolute filename of an entry file.
    # @param collection [Lifer::Collection] The collection for the entry.
    # @return [Lifer::Entry::HTML, Lifer::Entry::Markdown]
    def generate(file:, collection:)
      error!(file) unless File.exist?(file)

      case entry_type(file)
      when :html
        Lifer::Entry::HTML.new(file: file, collection: collection)
      when :markdown
        Lifer::Entry::Markdown.new(file: file, collection: collection)
      end
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
      raise StandardError, "file \"#{file}\" does not exist"
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
        "please set `#{self.class}.include_in_feeds` to true or false."
    end

    setting
  end

  # The full text of the entry.
  #
  # @return [String]
  def full_text
    File.readlines(file).join if file
  end

  # Using the current Lifer configuration, we can calculate the expected
  # permalink for the entry. This would be useful for indexes and feeds and so
  # on.
  #
  # @return [String] A permalink to the current entry.
  def permalink
    File.join Lifer.setting(:global, :host),
      Lifer::URIStrategy
        .find(collection.setting :uri_strategy)
        .new(root: Lifer.root)
        .output_file(self)
  end

  def to_html
    raise NotImplementedError, "subclasses must implemented this method"
  end

  self.include_in_feeds = false
end

require_relative "entry/html"
require_relative "entry/markdown"
