# A collection collects entries. Every entry can only be included in a single
# collection. Collections let the user group entries together into logical
# units. For example, if the user wants to present blog posts in one way and
# wiki pages in a different way, it would make sense to create separate "blog" and
# "wiki" collections.
#
# Each collection can have its own feeds and settings. The only special
# collection is the "root" collection, which is where all entries that don't fall
# into other collections end up.
#
class Lifer::Collection
  attr_reader :name

  class << self
    # Generate a new collection.
    #
    # @param name [String] The name of the new collection.
    # @param directory [String] The absolute path to the root directory of the
    #   collection.
    # @return [Lifer::Collection]
    def generate(name:, directory:)
      collection = new name: name, directory: directory
      collection.entries
      collection
    end
  end

  # Each collection has a collection of entries. An entry only belongs to one
  # collection.
  #
  # @return [Array<Lifer::Entry>] A collection of entries.
  def entries
    @entries ||=
      entry_glob.select { |entry|
        if Lifer.manifest.include? entry
          false
        elsif Lifer.ignoreable? entry.gsub("#{directory}/", "")
          false
        else
          Lifer.manifest << entry
          true
        end
      }.map { |entry| Lifer::Entry.generate file: entry, collection: self }
  end

  # To allow for flexible configuration, a layout file may be set by users to
  # either an absolute path or a path relative to the configuration file's
  # location. This method, though, always returns the absolute path.
  #
  # @return [String] The absolute path to the collection's layout file.
  def layout_file
    return setting :layout_file if setting(:layout_file).include?(Lifer.gem_root)
    return setting :layout_file if setting(:layout_file).include?(Lifer.root)

    config_directory = File.dirname Lifer.config_file

    [config_directory, setting(:layout_file)].join "/"
  end

  # Check whether the current collection is the root collection.
  #
  # @return [boolean]
  def root?
    name == :root
  end

  # Gets a Lifer setting, scoped to the current collection.
  #
  # @param *name [Array<Symbol>] A list of symbols that map to a nested Lifer
  #   setting (for the current collection).
  # @return [String, Nil] The setting as set in the Lifer project's
  #   configuration file.
  def setting(*name, strict: false)
    Lifer.setting *name, collection: self, strict: strict
  end

  private

  attr_reader :directory

  def initialize(name:, directory:)
    @name = name
    @directory = directory
  end

  def entry_glob
    Dir.glob("#{directory}/**/*")
      .select { |candidate| File.file? candidate }
      .select { |candidate| Lifer::Entry.supported? candidate }
  end
end

require_relative "selection"
