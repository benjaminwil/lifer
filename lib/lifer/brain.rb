require "fileutils"

require_relative "config"

# The brain is the object that keeps track of all essential information about
# the current Lifer project. Usually this information will be consumed via the
# `Lifer` module methods.
#
class Lifer::Brain
  # The default configuration file URI.
  #
  DEFAULT_CONFIG_FILE_URI = ".config/lifer.yaml"

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
    def init(root: Dir.pwd, config_file: nil) = new(root:, config_file:)
  end

  # Destroy any existing build output and then build the Lifer project with all
  # configured `Lifer::Builder`s.
  #
  # @param environment [Symbol] The current Lifer environment.
  # @return [void] This builds the Lifer site to the configured output
  #   directory.
  def build!(environment: :build)
    brainwash!

    prebuild_steps =
      case setting(:global, :prebuild)
      when Array, NilClass then setting(:global, :prebuild)
      when Hash then setting(:global, :prebuild, environment)
      end

    builder_list =
      case setting(:global, :build)
      when Array, NilClass then setting(:global, :build)
      when Hash then setting(:global, :build, environment)
      end

    Lifer::Builder.prebuild!(*prebuild_steps, root:)
    Lifer::Builder.build!(*builder_list, root:)
  end

  # Returns all collections and selections within the Lifer root.
  #
  # Collections only exist if they're explicitly configured in a configuration
  # file and they match a subdirectory within the root.
  #
  # Selections, on the other hand, reorganize entries from literal collections.
  # For example, a user could collect all of their entries that were authored
  # by Harry B. Cutler.
  #
  # Every Lifer build contains at least one collection. (That collection is
  # `:root`.)
  #
  # @return [Array<Lifer::Collection>] All the collections for the current Lifer
  #   project.
  def collections
    @collections ||= (generate_collections + generate_selections).to_a
  end

  # Returns the Lifer project's configuration object.
  #
  # @return [Lifer::Config] The Lifer configuration object.
  def config = (@config ||= Lifer::Config.build file: config_file_location)

  # Returns all entries that have been added to the manifest. If all is working
  # as intended, this should be every entry ever generated.
  #
  # @return [Set<Lifer::Entry>] All entries that currently exist.
  def entry_manifest = (@entry_manifest ||= Set.new)

  # A manifest of all Lifer project entries.
  #
  # @return [Set<Lifer::Entry>] A set of all entries.
  def manifest = (@manifest ||= Set.new)

  # Returns the build directory for the Lifer project's build output.
  #
  # @return [String] The Lifer build directory.
  def output_directory
    @output_directory ||=
      begin
        dir = "%s/%s" % [root, setting(:global, :output_directory)]

        return Pathname(dir) if Dir.exist? dir

        Dir.mkdir(dir)
        Pathname(dir)
      end
  end

  # The user can bring their own Ruby files to be read by Lifer. This ensures
  # they are loaded before the build starts.
  #
  # Note that the user's Bundler path may be in scope, so we need to skip
  # those Ruby files.
  #
  # @return [void]
  def require_user_provided_ruby_files!
    return if root.include? Lifer.gem_root

    rb_files = Dir.glob("#{root}/**/*.rb", File::FNM_DOTMATCH)

    if Bundler.bundle_path.to_s.include? root
      rb_files -=
        Dir.glob("#{Bundler.bundle_path}/**/*.rb", File::FNM_DOTMATCH)
    end

    rb_files.each do |rb_file|
      load rb_file
    end
  end

  # Given the tree of a setting name, and the setting scope, returns the setting
  # value. If the in-scope collection does not have a configured setting, this
  # method will return fallback settings (unless `:strict` is `true`).
  #
  # @example Usage:
  #     setting(:my, :great, :setting)
  #
  # @overload setting(path, ..., collection: nil, strict: false)
  #   @param name [Symbol] A key in the tree to a setting value.
  #   @param ... [Symbol] Any additional keys in the tree.
  #   @param collection [Lifer::Collection] The collection to scope the result
  #     to.
  #   @param strict [boolean] If true, do not return fallback setting values.
  #   @return [Array, String] The value of the requested setting.
  def setting(*name, collection: nil, strict: false)
    config.setting *name, collection_name: collection&.name, strict: strict
  end

  # Given the tag manifest, this returns an array of all tags for the current
  # project. This method is preferrable for accessing and querying for tags.
  #
  # @return [Array<Lifer::Tag>]
  def tags = tag_manifest.to_a

  # The tag manifest tracks the unique tags added to the project as they're added.
  # The writer method for this instance variable is used internally by Lifer when
  # adding new tags.
  #
  # @return [Set<Lifer::Tag>]
  def tag_manifest = (@tag_manifest ||= Set.new)

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

  # @return [Set<Lifer::Collection>]
  def generate_collections
    config.collectionables
      .map { |collection_name| [collection_name, "#{root}/#{collection_name}"] }
      .to_h
      .merge!({root: root})
      .map { |collection_name, directory|
        Lifer::Collection.generate name: collection_name, directory: directory
      }
      .to_set
  end

  # @private
  # Requires user-provided selection classes (classes that subclass
  # `Lifer::Selection` and implement an `#entries` method) so that users can
  # bring their own pseudo-collections of entries.
  #
  # @return [Set<Lifer::Selection>]
  def generate_selections
    return [] if config.file.to_s.include? Lifer.gem_root

    config.setting(:selections).map { |selection_name|
      klass = Lifer::Utilities.classify selection_name
      klass.generate
    }.to_set
  end
end
