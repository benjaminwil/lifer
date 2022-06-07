class Lifer::Brain
  attr_reader :root

  class << self
    def init(root: Dir.pwd)
      new(root: root)
    end
  end

  def build!
    Lifer::Builder::HTML.execute(root: root)
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

  private

  def initialize(root:)
    @root = root
  end

  def config_file_location
    File.join(root, ".config", "lifer.yaml")
  end
end
