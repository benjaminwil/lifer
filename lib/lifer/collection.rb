class Lifer::Collection
  attr_reader :name

  class << self
    def generate(name:, directory:)
      new name: name, directory: directory
    end
  end

  def entries
    @entries ||=
      Dir.glob("#{directory}/**/*.md").select { |entry|
        if Lifer.manifest.include? entry
          false
        elsif Lifer.ignoreable? entry.gsub("#{directory}/", "")
          false
        else
          Lifer.manifest << entry
          true
        end
      }.map { |entry| Lifer::Entry.new file: entry, collection: self }
  end

  def setting(name)
    Lifer.setting(name, collection: self)
  end

  private

  attr_reader :directory

  def initialize(name:, directory:)
    @name = name
    @directory = directory
  end
end
