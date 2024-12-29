require "fileutils"

class Lifer::Builder::TXT < Lifer::Builder
  self.name = :txt

  class << self
    def execute(root:)
      Dir.chdir Lifer.output_directory do
        new(root:).execute
      end
    end
  end

  def execute
    Lifer.collections(without_selections: true).each do |collection|
      collection.entries.each do |entry|
        next unless entry.class.output_extension == :txt

        relative_path = output_file entry
        absolute_path = File.join(Lifer.output_directory, relative_path)

        FileUtils.mkdir_p File.dirname(relative_path)

        if File.exist?(absolute_path)
          raise I18n.t("builder.file_conflict_error", path: absolute_path)
        end

        File.open(relative_path, "w") { |file| file.write entry.full_text }
      end
    end
  end

  private

  attr_reader :root

  def initialize(root:)
    @root = root
  end

  def output_file(entry)
    Lifer::URIStrategy
      .find(entry.collection.setting :uri_strategy)
      .new(root:)
      .output_file(entry)
  end
end
