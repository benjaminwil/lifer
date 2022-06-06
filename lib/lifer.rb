# frozen_string_literal: true

require "set"

require_relative "lifer/builder"
require_relative "lifer/collection"
require_relative "lifer/config"
require_relative "lifer/entry"
require_relative "lifer/layout"
require_relative "lifer/uri_strategy"

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
    def build(directory: Dir.pwd)
      @@root = directory

      Lifer::Builder::HTML.execute(root: directory)
    end

    def collections
      @@collections ||=
        begin
          collection_map =
            config.collections.map { |collection_name|
              [collection_name, "#{root}/#{collection_name}"]
            }.to_h.merge!({root: root})

          collection_map.map { |name, dir|
            Lifer::Collection.generate(name: name, directory: dir)
          }
        end
    end

    def ignoreable?(directory_or_file)
      directory_or_file.match?(/#{IGNORE_PATTERNS.join("|")}/)
    end

    def manifest
      @@manifest ||= Set.new
    end

    def root
      @@root
    rescue NameError
      Dir.pwd
    end

    def settings
      config.settings
    end

    private

    def config
      @@config ||= Lifer::Config.build(file: config_file_location)
    end

    def config_file_location
      "%s/.config/lifer.yaml" % File.expand_path(File.dirname(__FILE__))
    end
  end
end
