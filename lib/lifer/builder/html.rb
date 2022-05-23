require "fileutils"

class Lifer::Builder::HTML
  DEFAULT_OUTPUT_DIRECTORY_NAME = "_build"

  class << self
    def execute(contents:)
      new(contents: contents).execute
    end
  end

  def execute
    # Remove any existing output directory.
    FileUtils.rm_r(output_directory)

    # Go into the fresh build directory and generate each HTML file from the
    # given directory.
    Dir.chdir(output_directory) do
      @contents.collections.each do |collection|
        collection.entries.each do |entry|
          initialize_subdirectories_for entry

          File.open(uri_strategy.file_for(entry), "w") { |f|
            f.write Lifer::Layout.build(entry: entry)
          }
        end
      end
    end
  end

  private

  attr_reader :contents, :uri_strategy

  def initialize(contents:)
    @contents = contents
    @uri_strategy = Lifer::URIStrategy::Simple.new(directory: @contents.directory)
  end

  def initialize_subdirectories_for(entry)
    return if (dirname = uri_strategy.dirname_for(entry)).nil? ||
      Dir.exist?(dirname)

    FileUtils.mkdir_p uri_strategy.dirname_for(entry)
  end

  def output_directory
    dir = "%s/%s" % [
      @contents.directory,
      Lifer.settings[:output_directory] || DEFAULT_OUTPUT_DIRECTORY_NAME
    ]

    return Pathname(dir) if Dir.exist? dir

    Dir.mkdir(dir)
    Pathname(dir)
  end
end
