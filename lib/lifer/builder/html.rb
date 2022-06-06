require "fileutils"

# FIXME:
# This builder is not currently designed in a good way. Every builder should
# have an interface that lets us swap steps in and out in an easy way.
#
class Lifer::Builder::HTML
  DEFAULT_OUTPUT_DIRECTORY_NAME = "_build"

  class << self
    def execute(root:)
      new(root: root).execute
    end
  end

  def execute
    # Remove any existing output directory.
    FileUtils.rm_r(output_directory)

    # Go into the fresh build directory and generate each HTML file from the
    # given directory.
    Dir.chdir(output_directory) do
      Lifer.collections.each do |collection|
        collection.entries.each do |entry|
          initialize_subdirectories_for entry

          File.open(uri_strategy.file_for(entry), "w") { |f|
            f.write Lifer::Layout.build(
              entry: entry,
              template: layout_for(collection)
            )
          }
        end
      end
    end
  end

  private

  attr_reader :root, :uri_strategy

  def initialize(root:)
    @root = root
    @uri_strategy = Lifer::URIStrategy::Simple.new(directory: root)
  end

  def initialize_subdirectories_for(entry)
    return if (dirname = uri_strategy.dirname_for(entry)).nil? ||
      Dir.exist?(dirname)

    FileUtils.mkdir_p uri_strategy.dirname_for(entry)
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
