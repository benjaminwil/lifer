require "fileutils"

class Lifer::Builder::HTML
  FALLBACK_URI_STRATEGY = "simple"

  class << self
    def execute(root:)
      new(root: root).execute
    end
  end

  def execute
    Dir.chdir(Lifer.output_directory) do
      Lifer.collections.each do |collection|
        collection.entries.each do |entry|
          generate_output_directories_for entry, current_collection: collection
          generate_output_file_for entry, current_collection: collection
        end
      end
    end
  end

  private

  attr_reader :root

  def initialize(root:)
    @root = root
  end

  def generate_output_directories_for(entry, current_collection:)
    dirname =
      Pathname File.dirname(uri_strategy(current_collection).output_file(entry))
    FileUtils.mkdir_p dirname unless Dir.exist?(dirname)
  end

  def generate_output_file_for(entry, current_collection:)
    File.open(uri_strategy(current_collection).output_file(entry), "w") { |file|
      file.write(
        Lifer::Layout.build(
          entry: entry,
          template: Lifer.setting(:layout_file, collection: current_collection)
        )
      )
    }
  end

  def uri_strategy(current_collection)
    Lifer::URIStrategy.find_by_name(
      Lifer.setting(:uri_strategy, collection: current_collection)
    ).new(root: root)
  end
end
