require_relative "utilities"

class Lifer::Config
  DEFAULT_CONFIG_FILE =
    "%s/templates/config" % File.expand_path(File.dirname(__FILE__))
  DEFAULT_LAYOUT_FILE =
    "%s/templates/layout.html.erb" % File.expand_path(File.dirname(__FILE__))
  DEFAULT_SETTINGS = {
    layout_file: DEFAULT_LAYOUT_FILE,
    output_directory: "_build",
    uri_strategy: "simple"
  }
  REGISTERED_SETTINGS = DEFAULT_SETTINGS.keys

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

  attr_reader :file

  def collectionables
    raw.keys.select { |setting| has_collection_settings? setting }
  end

  def setting(name, collection_name: nil)
    collection_setting =
      if collection_name && settings[collection_name]
        settings[collection_name][name]
      end

    [collection_setting, settings[name], DEFAULT_SETTINGS[name]].detect(&:itself)
  end

  def settings(settings_hash = raw)
    settings_hash.select { |setting, value|
      value = settings(value) if value.is_a?(Hash)

      next unless REGISTERED_SETTINGS.include?(setting) || has_collection_settings?(setting)

      [setting, value]
    }.compact.to_h
  end

  private

  def initialize(file:)
    @file = Pathname(file)
  end

  def collection_candidates
    subdirectories = Dir.glob("#{root_directory}/**/*")
      .select { |entry| File.directory? entry }
      .map { |entry| entry.gsub("#{root_directory}/", "") }

    subdirectories
      .select { |dir| !Lifer.ignoreable? dir }.map(&:to_sym).sort.reverse
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
    raw.reject { |setting, _| REGISTERED_SETTINGS.include? setting }
  end
end
