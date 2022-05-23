class Lifer::Contents
  attr_reader :directory

  class << self
    def init(directory: Dir.pwd)
      new directory: directory
    end
  end

  def collections
    @collections ||= collection_map.map { |name, directory|
      Lifer::Collection.generate(name: name, directory: directory)
    }
  end

  private

  def collection_map
    Lifer.collections.map { |collection|
      [collection, "#{directory}/#{collection}"]
    }.to_h.merge!({root: directory})
  end

  def initialize(directory:)
    @directory = Pathname(directory)
  end
end
