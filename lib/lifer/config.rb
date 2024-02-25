require_relative "utilities"

class Lifer::Config
  GLOBAL_SETTINGS = [
    :build,
    :host,
    :output_directory
  ]
  DEFAULT_CONFIG_FILE = "%s/lib/lifer/templates/config.yaml" % Lifer.gem_root
  DEFAULT_LAYOUT_FILE = "%s/lib/lifer/templates/layout.html.erb" % Lifer.gem_root
  DEFAULT_IMPLICIT_SETTINGS = {
    layout_file: DEFAULT_LAYOUT_FILE
  }
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
        puts "No configuration file at #{file}. Using default configuration."

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
    raw.keys.select { |setting| has_collection_settings? setting }
  end

  # This method allows user scripts and extensions to register arbitrary
  # settings in their configuration YAML files.
  #
  # @param *settings [*Symbol, *Hash] A list of symbols and/or hashs to be added
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
    return settings.dig(*name_in_collection) if (strict && collection_name)

    candidates = [
      settings.dig(*name),
      default_settings.dig(*name),
      DEFAULT_IMPLICIT_SETTINGS.dig(*name)
    ]
    candidates.unshift settings.dig(*name_in_collection) if name_in_collection

    candidates.detect &:itself
  end

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
    subdirectories = Dir.glob("#{root}/**/*")
      .select { |entry| File.directory? entry }
      .map { |entry| entry.gsub("#{root}/", "") }

    subdirectories
      .select { |dir| !Lifer.ignoreable? dir }.map(&:to_sym).sort.reverse
  end

  def default_settings
    @default_settings ||=
      Lifer::Utilities.symbolize_keys(YAML.load_file DEFAULT_CONFIG_FILE).to_h
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
