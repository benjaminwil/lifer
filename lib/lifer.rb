# frozen_string_literal: true

require "set"

# The root Lifer module is a great entrypoint into the system, with convenience
# methods to access global resources like collections and configuration settings.
#
module Lifer
  # Lifer considers files and directories that have the following names or
  # contain the following patterns special and ignoreable when they're at the
  # root of the Lifer project.
  #
  IGNORE_DIRECTORIES = [
    "assets",
    "bin",
    "vendor"
  ]

  # Lifer projects ignore files and directories that contain particular patterns.
  #
  IGNORE_PATTERNS = [
    "^(\\.)",     # Starts with a dot.
    "^(_)",       # Starts with an underscore.
    "(\\/\\.)+"   # Contains a dot directory.
  ] | IGNORE_DIRECTORIES.map { |d| "^(#{d})" }

  # We expect frontmatter in any file to be provided in the following format.
  #
  FRONTMATTER_REGEX = /^---\n(.*)---\n/m

  class << self
    # The first time `Lifer.brain` is referenced, we build a new `Lifer::Brain`
    # object that is used and reused until the current process has ended.
    #
    # @param root [String] The absolute path to the Lifer project root.
    # @param config_file [String] The absolute path to the Lifer project's
    #   configuration file.
    # @return [Lifer::Brain] A brain!
    def brain(root: Dir.pwd, config_file: nil)
      @@brain ||= Lifer::Brain.init root:, config_file:
    end

    # Initiates the Lifer build process.
    #
    # @param environment [Symbol] The name of the current Lifer environment.
    #   Valid environments are `:build` or `:serve`.
    # @return [void]
    def build!(environment: :build) = (brain.build! environment:)

    # List all collections in the project. By default, selections are also
    # included.
    #
    # @param without_selections [boolean] Whether to include selections in the list.
    #   (Default: false.)
    # @return [Array<Lifer::Collection>] A list of all collections.
    def collections(without_selections: false)
      return brain.collections unless without_selections

      brain.collections.select { _1.class == Lifer::Collection }
    end

    # Used to locate the configuration file being used by the current Lifer
    # project.
    #
    # @return [Pathname] The path to the current Lifer config file.
    def config_file = brain.config.file

    # A set of all entries currently in the project.
    #
    # @fixme Do we need this as well as `Lifer.manifest`?
    #
    # @return [Set] All entries.
    def entry_manifest = brain.entry_manifest

    # This convenience method locates the Ruby gem root, which is always
    # distinct from the Lifer project root. This is helpful, for example, if
    # default templates provided by the gem are required in the current project.
    #
    # @return [String] The absolute path to the installed Lifer gem root.
    def gem_root = File.dirname(__dir__)

    # Check if the given path matches the Lifer ignore patterns.
    #
    # @param directory_or_file [String] The path to a directory or file.
    # @return [boolean] True if the directory of file is ignoreable.
    def ignoreable?(directory_or_file)
      directory_or_file.match?(/#{IGNORE_PATTERNS.join("|")}/)
    end

    # A set of all entries currently in the project.
    #
    # @fixme Do we need this as well as `Lifer.manifest`?
    #
    # @return [Set] All entries.
    def manifest = brain.manifest

    # The build directory for the Lifer project.
    #
    # @return [Pathname] The absolute path to the directory where the Lifer
    #   project would be built to.
    def output_directory = brain.output_directory

    # Returns false if the Lifer project will be built with parallelism. This
    # should return false almost always--unless you've explicitly set the
    # `LIFER_UNPARALLELIZED` environment variable before running the program.
    #
    # This method is used internally by Lifer to determine whether features that
    # would normally run in parallel should *not* run in parallel for some reason.
    #
    # @return [boolean] Returns whether parallelism is disabled.
    def parallelism_disabled? = ENV["LIFER_UNPARALLELIZED"].is_a?(String)

    # Register new settings so that they are "safe" and can be read from a Lifer
    # configuration file. Unregistered settings are ignored.
    #
    # @example Usage
    #    register_settings(
    #      :hidden,
    #      :birthday,
    #      jsonfeed: [:enabled, :url, :style]
    #    )
    #
    # @overload register_settings(setting, ...)
    #  @param setting [Symbol, Hash] A setting or setting tree to be registered.
    #  @param ... [Symbol, Hash] More settings or settings trees to be
    #    registered.
    #  @return [void]
    def register_settings(*settings) = brain.config.register_settings(*settings)

    # The project brain.
    #
    # @return [Lifer::Brain] The project brain.
    def root = brain.root

    # Given a path to a setting, with or without a collection scope, get the
    # current configured value for that setting.
    #
    # Note that if a collection does not have a setting set, the setting
    # returned will be the Lifer root collection setting or the default setting
    # unless the `:strict` keyword argument is set to `true`.
    #
    # @overload setting(..., collection: nil, strict: false)
    #   @param ... [Symbol] A list of settings to traverse the settings tree with.
    #   @param collection [Lifer::Collection] The collection scope for the
    #     wanted setting.
    #   @param strict [boolean] Choose whether to strictly return the collection
    #     setting or to fallback to the Lifer root and default settings.
    #     (Default: false.)
    #   @return [String, NilClass] The value of the best in-scope setting.
    def setting(*name, collection: nil, strict: false)
      brain.setting *name, collection: collection, strict: strict
    end

    # The project's current settings tree.
    #
    # @return [Hash] The `Lifer::Config#settings`.
    def settings = brain.config.settings

    # All of the tags represented in Lifer entries for the current project.
    #
    # @return [Array<Lifer::Tag>] The complete list of tags.
    def tags = brain.tags

    # A set of all tags added to the project. Prefer using the `#tags` method
    # for tag queries.
    #
    # @return [Set<Lifer::Tag>] The complete set of tags.
    def tag_manifest = brain.tag_manifest
  end
end

require "i18n"
I18n.load_path += Dir["%s/locales/*.yml" % Lifer.gem_root]
I18n.available_locales = [:en]

# `Lifer::Shared` contains modules that that may or may not be included on other
# classes required below.
#
require_relative "lifer/shared"

require_relative "lifer/brain"
require_relative "lifer/builder"
require_relative "lifer/collection"
require_relative "lifer/entry"
require_relative "lifer/message"
require_relative "lifer/tag"
require_relative "lifer/uri_strategy"
