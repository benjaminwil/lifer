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
          template: layout_for(current_collection)
        )
      )
    }
  end

  def layout_for(collection)
    if (collection_settings = Lifer.settings[collection.name])
      collection_settings[:layout_file]
    else
      Lifer.settings[:layout_file]
    end
  end

  def uri_strategy(current_collection)
    collection_settings =
      Lifer.settings[current_collection.name] || Lifer.settings[:root]
    current_uri_strategy =
      collection_settings && collection_settings[:uri_strategy] ||
        FALLBACK_URI_STRATEGY

    Lifer::URIStrategy.find_by_name(current_uri_strategy).new(root: root)
  end
end
