require "fileutils"

require_relative "config"

# The brain is the object that keeps track of all essential information about
# the current Lifer project. Usually this information will be consumed via the
# `Lifer` module methods.
#
class Lifer::Brain
  DEFAULT_CONFIG_FILE_URI = ".config/lifer.yaml"
  DEFAULT_OUTPUT_DIRECTORY_NAME = "_build"

  attr_reader :root

  class << self
    # The preferred initializer for the single `Lifer::Brain` object that
    # represents the user's Lifer project.
    #
    # @param root [String] The root Lifer project directory.
    # @param config_file [String] A path to the correct Lifer config file. If
    #   left empty, the brain uses the one at the default path or the one
    #   bundled with the gem.
    # @return [Lifer::Brain] The brain object for the current Lifer project.
    def init(root: Dir.pwd, config_file: nil)
      new(root: root, config_file: config_file)
    end
  end

  # Destroy any existing build output and then build the Lifer project with all
  # configured `Lifer::Builder`s.
  #
  # @return [void] This builds the Lifer site to the configured output
  #   directory.
  def build!
    brainwash!

    Lifer::Builder.build! *setting(:global, :build), root: root
  end

  # Collections only exist if they're explicitly configured in a configuration
  # file and they match a subdirectory within the root.
  #
  # Every Lifer build contains at least one collection. (That collection is
  # `:root`.)
  #
  # @return [Array<Lifer::Collection] All the collections for the current Lifer
  #   project.
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

  attr_reader :config_file_location

  def initialize(root:, config_file:)
    @root = root
    @config_file_location = build_config_file_location(config_file)
  end

  def brainwash!
    FileUtils.rm_r output_directory
    FileUtils.mkdir_p output_directory
  end

  def build_config_file_location(path)
    return File.join(root, DEFAULT_CONFIG_FILE_URI) if path.nil?

    path.start_with?("/") ? path : File.join(root, path)
  end

  # FIXME:
  # Do collections work with sub-subdirectories? For example, what if the
  # configured collection maps to a directory:
  #
  #     subdirectory_one/sub_subdirectory_one
  #
  # @return [Set<Lifer::Collection>]
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
