require_relative "utilities"

class Lifer::Config
  DEFAULT_CONFIG_FILE =
    "%s/templates/config" % File.expand_path(File.dirname(__FILE__))
  DEFAULT_LAYOUT_FILE =
    "%s/templates/layout.html.erb" % File.expand_path(File.dirname(__FILE__))
  DEFAULT_IMPLICIT_SETTINGS = {
    layout_file: DEFAULT_LAYOUT_FILE
  }
  DEFAULT_REGISTERED_SETTINGS = [
    :author,
    :description,
    {entries: [:default_title]},
    {feed: [:builder, :uri]},
    :language,
    :layout_file,
    :title,
    :uri_strategy
  ]

  class << self
    def build(file:)
      if File.file? file
        new file: file
      else
        puts "No configuration file at #{file}. Using default configuration."

        new file: DEFAULT_CONFIG_FILE
      end
    end
  end

  attr_accessor :registered_settings
  attr_reader :file

  def collectionables
    raw.keys.select { |setting| has_collection_settings? setting }
  end

  # Returns the best in-scope setting value, where the best is the current
  # collection's setting, then the root collection's setting, and then Lifer's
  # default setting. If none these are available the method will return `nil`.
  #
  # @param  name [Symbol] The configuration setting.
  # @param  collection_name [Symbol] A collection name.
  # @return [String] The value of the best in-scope setting.
  def setting(*name, collection_name: nil)
    name_in_collection = name.dup.unshift(collection_name) if collection_name

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

      next unless DEFAULT_REGISTERED_SETTINGS.include?(setting) ||
        has_collection_settings?(setting)

      [setting, value]
    }.compact.to_h
  end

  private

  def initialize(file:)
    @file = Pathname(file)
    @registered_settings = DEFAULT_REGISTERED_SETTINGS.to_set
  end

  def collection_candidates
    subdirectories = Dir.glob("#{root_directory}/**/*")
      .select { |entry| File.directory? entry }
      .map { |entry| entry.gsub("#{root_directory}/", "") }

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

  def root_directory
    @root_directory ||= ("%s/.." % File.expand_path(File.dirname(@file)))
  end

  def unregistered_settings
    raw.reject { |setting, _| DEFAULT_REGISTERED_SETTINGS.include? setting }
  end
end
