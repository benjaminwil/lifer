class Lifer::Collection
  attr_reader :name, :entries

  class << self
    def generate(name:, directory:)
      new(name: name, entries: entries_from(directory))
    end

    def entries_from(directory)
      Dir.glob("#{directory}/**/*.md").select { |entry|
        if Lifer.manifest.include? entry
          false
        elsif Lifer.ignoreable? entry.gsub("#{directory}/", "")
          false
        else
          Lifer.manifest << entry
          true
        end
      }.map { |entry| Lifer::Entry.new(file: entry) }
    end
  end

  private

  def initialize(name:, entries:)
    @name = name
    @entries = entries
  end
end
