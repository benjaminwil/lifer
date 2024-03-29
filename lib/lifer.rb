# frozen_string_literal: true

require "set"

module Lifer
  IGNORE_DIRECTORIES = [
    "assets",
    "bin",
    "vendor"
  ]

  IGNORE_PATTERNS = [
    "^(\\.)",     # Starts with a dot.
    "^(_)",       # Starts with an underscore.
    "(\\/\\.)+"   # Contains a dot directory.
  ] | IGNORE_DIRECTORIES.map { |d| "^(#{d})" }

  class << self
    def brain(root: Dir.pwd, config_file: nil)
      @@brain ||= Lifer::Brain.init(root: root, config_file: config_file)
    end

    def build!
      brain.build!
    end

    def collections
      brain.collections
    end

    # Used to locate the configuration file being used by the current Lifer
    # project.
    #
    # @return [Pathname] The path to the current Lifer config file.
    def config_file
      brain.config.file
    end

    def entry_manifest
      brain.entry_manifest
    end

    def gem_root
      File.dirname __dir__
    end

    def ignoreable?(directory_or_file)
      directory_or_file.match?(/#{IGNORE_PATTERNS.join("|")}/)
    end

    def manifest
      brain.manifest
    end

    def output_directory
      brain.output_directory
    end

    def register_settings(*settings)
      brain.config.register_settings(*settings)
    end

    def root
      brain.root
    end

    def setting(*name, collection: nil, strict: false)
      brain.setting *name, collection: collection, strict: strict
    end

    def settings
      brain.config.settings
    end
  end
end

# `Lifer::Shared` contains modules that that may or may not be included on other
# classes required below.
#
require_relative "lifer/shared"

require_relative "lifer/brain"
require_relative "lifer/builder"
require_relative "lifer/collection"
require_relative "lifer/entry"
require_relative "lifer/uri_strategy"
