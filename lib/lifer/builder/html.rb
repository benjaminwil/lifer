require "fileutils"

# This builder makes HTML documents out of any entry type that responds to
# `#to_html`.
#
class Lifer::Builder::HTML < Lifer::Builder
  self.name = :html

  require_relative "html/from_erb"

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
    Lifer.collections.each do |collection|
      collection.entries.each do |entry|
        generate_output_directories_for entry
        generate_output_file_for entry
      end
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
  # For the given entry, ensure all of the paths to the file exist so the file
  # can be safely written to.
  #
  # @param entry [Lifer::Entry] An entry.
  # @return [Array<String>] An array containing the directories that were just
  #   created (or already existed).
  def generate_output_directories_for(entry)
    dirname = Pathname File.dirname(output_file entry)
    FileUtils.mkdir_p dirname unless Dir.exist?(dirname)
  end

  # @private
  # For the given entry, generate the production entry.
  #
  # @param entry [Lifer::Entry] An entry.
  # @return [Integer] The length of the written file. We should not care about
  #   this return value.
  def generate_output_file_for(entry)
    File.open(output_file(entry), "w") { |file|
      file.write(LayoutFromERB.build entry: entry)
    }
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
