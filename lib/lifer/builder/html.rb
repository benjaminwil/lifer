require "fileutils"

class Lifer::Builder::HTML
  DEFAULT_OUTPUT_DIRECTORY_NAME = "_build"

  class << self
    def execute(root:)
      new(root: root).execute
    end
  end

  def execute
    # Remove any existing output directory.
    #
    FileUtils.rm_r(output_directory)

    # Go into the fresh build directory and generate each HTML file from the
    # given directory.
    #
    Dir.chdir(output_directory) do
      Lifer.collections.each do |collection|
        collection.entries.each do |entry|
          generate_output_directories_for entry
          generate_output_file_for entry, current_collection: collection
        end
      end
    end
  end

  private

  attr_reader :root, :uri_strategy

  def initialize(root:)
    @root = root
    @uri_strategy = Lifer::URIStrategy::Simple.new(root: root)
  end

  def generate_output_directories_for(entry)
    dirname = Pathname File.dirname(uri_strategy.output_file(entry))
    FileUtils.mkdir_p dirname unless Dir.exist?(dirname)
  end

  def generate_output_file_for(entry, current_collection:)
    File.open(uri_strategy.output_file(entry), "w") { |file|
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

  def output_directory
    dir = "%s/%s" % [
      root,
      Lifer.settings[:output_directory] || DEFAULT_OUTPUT_DIRECTORY_NAME
    ]

    return Pathname(dir) if Dir.exist? dir

    Dir.mkdir(dir)
    Pathname(dir)
  end
end
