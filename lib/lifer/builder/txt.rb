require "fileutils"

# Builds a text file from a text file.
#
# Note that the collection's URI strategy is still in play here, so the output
# path may be different than the input path.
#
class Lifer::Builder::TXT < Lifer::Builder
  self.name = :txt

  class << self
    # Builds text files within the Lifer project's build directory.
    #
    # @param root [String] The Lifer root directory.
    # @return [void]
    def execute(root:)
      Dir.chdir Lifer.output_directory do
        new(root:).execute
      end
    end
  end

  # Builds each entry in each collection, including any requirements (like
  # subdirectories) those entries have.
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

  def initialize(root:)
    @root = root
  end

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

  def generate_output_file_for(entry)
    return unless entry.class.output_extension == :txt

    relative_path = output_file entry
    absolute_path = File.join(Lifer.output_directory, relative_path)

    FileUtils.mkdir_p File.dirname(relative_path)

    if File.exist?(absolute_path)
      raise I18n.t("builder.file_conflict_error", path: absolute_path)
    end

    File.open(relative_path, "w") { |file| file.write entry.full_text }
  end

  def output_file(entry)
    Lifer::URIStrategy
      .find(entry.collection.setting :uri_strategy)
      .new(root:)
      .output_file(entry)
  end
end
