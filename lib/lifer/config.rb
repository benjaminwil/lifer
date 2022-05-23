require_relative "utilities"

class Lifer::Config
  DEFAULT = "%s/templates/config" % File.expand_path(File.dirname(__FILE__))

  REGISTERED_SETTINGS = [
    :output_directory,
    :uri_strategy
  ]

  class << self
    def build(file:)
      if File.file? file
        new file: file
      else
        puts "No configuration file at #{file}. Using default configuration."

        new file: DEFAULT
      end
    end
  end

  attr_reader :file

  def collections
    raw.keys.select { |setting| has_settings? setting }
  end

  def settings
    raw.select { |setting, _|
      if REGISTERED_SETTINGS.include? setting
        true
      elsif has_settings? setting
        true
      end
    }
  end

  private

  def initialize(file:)
    @file = Pathname(file)
  end

  def has_settings?(subdirectory)
    subdirectories_with_settings =
      subdirectories & unregistered_settings.keys

    subdirectories_with_settings.include? subdirectory
  end

  def raw
    @raw ||= Lifer::Utilities.symbolize_keys(
      YAML.load_file(file).to_h
    )
  end

  def root_directory
    @root_directory ||= ("%s/.." % File.expand_path(File.dirname(@file)))
  end

  def subdirectories
    subs = Dir.glob("#{root_directory}/**/*")
      .select { |entry| File.directory? entry }
      .map { |entry| entry.gsub("#{root_directory}/", "") }

    subs.select { |dir| !Lifer.ignoreable? dir }.map(&:to_sym).sort.reverse
  end

  def unregistered_settings
    raw.reject { |setting, _| REGISTERED_SETTINGS.include? setting }
  end
end
