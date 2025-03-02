require_relative "utilities"

# This class is responsible for reading the Lifer configuration YAML file. This
# file should provided by the user, but the Lifer Ruby gem does provide a default
# file, as well.
#
class Lifer::Config
  # Some settings may take variants based on the current Lifer environment. The
  # environments with variant configurations include "build" (for static builds,
  # or: production mode) and "serve" (for development mode).
  #
  CONFIG_ENVIRONMENTS = [:build, :serve]

  # The "global" section of the config file is the one explicitly special part
  # of the config. It's used to provide information Lifer needs to keep track of
  # across the entire pre-build and build process.
  #
  GLOBAL_SETTINGS = [
    {build: CONFIG_ENVIRONMENTS},
    :host,
    :output_directory,
    {prebuild: CONFIG_ENVIRONMENTS}
  ]

  # The Lifer Ruby gem provides a default configuration file as a template.
  #
  DEFAULT_CONFIG_FILE = "%s/lib/lifer/templates/config.yaml" % Lifer.gem_root

  # The Lifer Ruby gem provides a default layout file (ERB) as a template.
  #
  DEFAULT_LAYOUT_FILE = "%s/lib/lifer/templates/layout.html.erb" % Lifer.gem_root

  # Provides "implicit settings" that may not be set anywhere but really do
  # require a value.
  #
  # @fixme I don't think this really belongs here. But in some cases we need
  #   to provide the implicit setting key and a default value when calling the
  #   `#setting` method. It would be nicer if the HTML builder handled this,
  #   somehow.
  #
  DEFAULT_IMPLICIT_SETTINGS = {
    layout_file: DEFAULT_LAYOUT_FILE
  }

  # A setting must be registered before Lifer will read it and do anything with
  # it. The following settings are registered by default.
  #
  # (Note that when users add their own custom Ruby classes with custom
  # settings, they must register those settings dynamically. Search this source
  # code for `Lifer.register_settings` to see examples of settings being
  # registered.)
  #
  DEFAULT_REGISTERED_SETTINGS = [
    :author,
    :description,
    {entries: [:default_title]},
    {feed: [:builder, :uri]},
    {global: GLOBAL_SETTINGS},
    :language,
    :layout_file,
    :selections,
    :title,
    :uri_strategy
  ]

  class << self
    # A configuration file must be present in order to bootstrap Lifer. If a
    # configuration file cannot be found at the given path, then the default
    # configuration file is used.
    #
    # @param file [String] The path to the user-provided configuration file.
    # @return [void]
    def build(file:, root: Lifer.root)
      if File.file? file
        new file: file, root: root
      else
        Lifer::Message.log("config.no_config_file_at", file:)

        new file: DEFAULT_CONFIG_FILE, root: root
      end
    end
  end

  attr_accessor :registered_settings
  attr_reader :file

  # Provides Lifer with a list of collections as interpreted by reading the
  # configuration YAML file. Collectionables are used to generate collections.
  #
  # @return [Array<Symbol>] A list of non-root collection names.
  def collectionables
    @collectionables ||=
      raw.keys.select { |setting| has_collection_settings? setting }
  end

  # This method allows user scripts and extensions to register arbitrary
  # settings in their configuration YAML files.
  #
  # @param settings [*Symbol, *Hash] A list of symbols and/or hashs to be added
  #   to Lifer's registered settings.
  # @return [void]
  def register_settings(*settings)
    settings.each do |setting|
      registered_settings << setting
    end
  end

  # Returns the best in-scope setting value, where the best is the current
  # collection's setting, then the root collection's setting, and then Lifer's
  # default setting. If none these are available the method will return `nil`.
  #
  # @param name [Symbol] The configuration setting.
  # @param collection_name [Symbol] A collection name.
  # @param strict [boolean] Strictly return the collection setting without
  #   falling back to higher-level settings.
  # @return [String, NilClass] The value of the best in-scope setting.
  def setting(*name, collection_name: nil, strict: false)
    name_in_collection = name.dup.unshift(collection_name) if collection_name

    return if strict && collection_name.nil?
    return dig_from(settings, *name_in_collection) if (strict && collection_name)

    candidates = [
      dig_from(settings, *name),
      dig_from(default_settings, *name),
      dig_from(DEFAULT_IMPLICIT_SETTINGS, *name)
    ]
    candidates.unshift dig_from(settings, *name_in_collection) if name_in_collection

    candidates.detect &:itself
  end

  # Provide a nice, readable, registered settings hash. If given a subset of
  # settings (like a collection's settings), it will also provide a hash of
  # registered settings within scope.
  #
  # @param settings_hash [Hash] A hash of settings.
  # @return [Hash] A compact hash of registered settings.
  def settings(settings_hash = raw)
    settings_hash.select { |setting, value|
      value = settings(value) if value.is_a?(Hash)

      next unless registered_setting?(setting)

      [setting, value]
    }.compact.to_h
  end

  private

  attr_reader :root

  def initialize(file:, root:)
    @file = Pathname(file)
    @root = Pathname(root)

    @registered_settings = DEFAULT_REGISTERED_SETTINGS.to_set
  end

  def collection_candidates
    @collection_candidates ||=
      Dir.glob("#{root}/**/*")
        .select { |entry| File.directory? entry }
        .map { |entry| entry.gsub("#{root}/", "") }
        .select { |dir| !Lifer.ignoreable? dir }
        .map(&:to_sym)
        .sort
        .reverse
  end

  def default_settings
    @default_settings ||=
      Lifer::Utilities.symbolize_keys(YAML.load_file DEFAULT_CONFIG_FILE).to_h
  end

  def dig_from(hash, *keys)
    keys.reduce(hash) { |result, key|
      result.is_a?(Hash) || result.is_a?(Array) ? result[key] : nil
    }
  end

  def has_collection_settings?(settings_key)
    confirmed_collections = collection_candidates & unregistered_settings.keys

    confirmed_collections.include? settings_key
  end

  def raw
    @raw ||= Lifer::Utilities.symbolize_keys(
      YAML.load_file(file).to_h
    )
  end

  def registered_setting?(setting)
    simple_settings = registered_settings.select { _1.is_a? Symbol }
    return true if simple_settings.include?(setting)

    hash_settings = registered_settings.select { _1.is_a? Hash }
    return true if hash_settings.flat_map(&:keys).include?(setting)

    has_collection_settings? setting
  end

  def unregistered_settings
    raw.reject { |setting, _| registered_settings.include? setting }
  end
end
