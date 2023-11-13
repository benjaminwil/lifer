require "fileutils"

class Lifer::Brain
  DEFAULT_OUTPUT_DIRECTORY_NAME = "_build"

  attr_reader :root

  class << self
    def init(root: Dir.pwd)
      new(root: root)
    end
  end

  def build!
    brainwash!

    [Lifer::Builder::HTML].each do |builder|
      builder.execute root: root
    end
  end

  # Collections only exist if they're explicitly configured in a configuration
  # file and they match a subdirectory within the root.
  #
  # Every Lifer build contains at least one collection. (That collection is
  # `:root`.)
  #
  def collections
    @collections ||= generate_collections
  end

  def config
    @config ||= Lifer::Config.build file: config_file_location
  end

  def manifest
    @manifest ||= Set.new
  end

  def output_directory
    @output_directory ||=
      begin
        dir = "%s/%s" % [root, setting(:global, :output_directory)]

        return Pathname(dir) if Dir.exist? dir

        Dir.mkdir(dir)
        Pathname(dir)
      end
  end

  def setting(*name, collection: nil)
    config.setting *name, collection_name: collection&.name
  end

  private

  def initialize(root:)
    @root = root
  end

  def brainwash!
    FileUtils.rm_r output_directory
    FileUtils.mkdir_p output_directory
  end

  def config_file_location
    File.join(root, ".config", "lifer.yaml")
  end

  # FIXME:
  # Do collections work with sub-subdirectories? For example, what if the
  # configured collection maps to a directory:
  #
  #     subdirectory_one/sub_subdirectory_one
  #
  def generate_collections
    config.collectionables
      .map { |collection_name| [collection_name, "#{root}/#{collection_name}"] }
      .to_h
      .merge!({root: root})
      .map { |collection_name, directory|
        Lifer::Collection.generate name: collection_name, directory: directory
      }
  end
end
