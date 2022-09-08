require "fileutils"

class Lifer::Brain
  DEFAULT_OUTPUT_DIRECTORY_NAME = "_build"

  attr_reader :root

  class << self
    def init(root: Dir.pwd)
      new(root: root)
    end
  end

  def build!
    brainwash!

    [Lifer::Builder::HTML].each do |builder|
      builder.execute root: root
    end
  end

  def collections
    @collections ||=
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

  def config
    @config ||= Lifer::Config.build(file: config_file_location)
  end

  def manifest
    @manifest ||= Set.new
  end

  def output_directory
    @output_directory ||=
      begin
        dir = "%s/%s" % [root, Lifer.setting(:output_directory)]

        return Pathname(dir) if Dir.exist? dir

        Dir.mkdir(dir)
        Pathname(dir)
      end
  end

  def setting(name, collection: nil)
    config.setting name, collection_name: collection&.name
  end

  private

  def initialize(root:)
    @root = root
  end

  def brainwash!
    FileUtils.rm_r output_directory
    FileUtils.mkdir_p output_directory
  end

  def config_file_location
    File.join(root, ".config", "lifer.yaml")
  end
end
