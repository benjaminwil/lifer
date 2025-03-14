require "fileutils"

# This builder makes HTML documents out of any entry type that responds to
# `#to_html` and writes them to the configured Lifer output directory.
#
# The HTML builder depends on the collection's layout file. Layout files can be
# ERB[1] or Liquid[2] template files. The layout file yields entry contents
# via a `content` call that is parsed by ERB or Liquid.
#
# Layout files can also include other contextual information about the current
# Lifer project to provide "normal website features" like navigation links,
# indexes, and so on. Context is provided via:
#
#  - `my_collection_name`: Or, any collection by name.
#
#    For example, you can iterate over the entries of any named collection by
#    accessing the collection like this:
#
#        my_collection.entries
#
#  - `settings`: Serialized Lifer settings from the configuration file.
#
#  - `collections`: A list of collections.
#
#  - `content`: The content of the current entry.
#
# The `:content` variable is especially powerful, as it also parses any
# given entry that's an ERB file with the same local variables in context.
#
# [1]: https://docs.ruby-lang.org/en/3.3/ERB.html
# [2]: https://shopify.github.io/liquid/
#
class Lifer::Builder::HTML < Lifer::Builder
  self.name = :html

  require_relative "html/from_erb"
  require_relative "html/from_liquid"

  class << self
    # Traverses and renders each entry for each collection in the configured
    # output directory for the Lifer project.
    #
    # @param root [String] The Lifer root.
    # @return [void]
    def execute(root:)
      Dir.chdir Lifer.output_directory do
        new(root: root).execute
      end
    end
  end

  # Traverses and renders each entry for each collection.
  #
  # @return [void]
  def execute
    Lifer.collections(without_selections: true).each do |collection|
      generate_output_directories_for collection
      generate_output_entries_for collection
    end
  end

  private

  attr_reader :root

  # @private
  # @param root [String] The Lifer root.
  # @return [void]
  def initialize(root:)
    @root = root
  end

  # @private
  # For the given collection, ensure all required directories and
  # subdirectories exist so the entry output can be safely written to.
  #
  # @param collection [Lifer::Collection] A collection.
  # @return [void]
  def generate_output_directories_for(collection)
    directories = collection.entries
      .map { |entry| File.dirname(output_file entry) }
      .uniq

    Lifer::Utilities.parallelized(directories) do |directory|
      FileUtils.mkdir_p directory unless Dir.exist?(directory)
    end
  end

  def generate_output_entries_for(collection)
    Lifer::Utilities.parallelized(collection.entries) do |entry|
      generate_output_file_for entry
    end
  end

  # @private
  # For the given entry, generate the production entry.
  #
  # @param entry [Lifer::Entry] An entry.
  # @raise [StandardError] If the file already exists, we kill the program. The
  #   end user needs to ensure there are no entry conflicts.
  # @return [Integer, NilClass] The length of the written file, or nil if the
  #   entry cannot be output to HTML.  We should not care about this return
  #   value.
  def generate_output_file_for(entry)
    return unless entry.class.output_extension == :html

    relative_path = output_file entry
    absolute_path = File.join(Lifer.output_directory, relative_path)

    if File.exist?(absolute_path)
      raise I18n.t("builder.file_conflict_error", path: absolute_path)
    end

    File.open(relative_path, "w") { |file|
      file.write layout_class_for(entry).build(entry: entry)
    }
  end

  # @private
  # Given the path to a layout file, this method determines what layout builder
  # will be used. The builder class must implement a `.build` class method.
  #
  # @param entry [Lifer::Entry] An entry
  # @return [Class] A layout builder class name.
  def layout_class_for(entry)
    case entry.collection.setting(:layout_file)
    when /.*\.erb$/ then FromERB
    when /.*\.liquid$/ then FromLiquid
    else
      file = entry.collection.setting(:layout_file)
      raise I18n.t(
        "builder.html.no_builder_error",
        file:,
        type: File.extname(file)
      )
    end
  end

  # @private
  # Using the URI strategy configured for the entry's collection, generate a
  # permalink (or output filename).
  #
  # @param entry [Lifer::Entry] The entry.
  # @return [String] The permalink to the entry.
  def output_file(entry)
    Lifer::URIStrategy
      .find(entry.collection.setting :uri_strategy)
      .new(root: root)
      .output_file(entry)
  end
end
