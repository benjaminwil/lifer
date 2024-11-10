class Lifer::URIStrategy
  class Root < Lifer::URIStrategy
    self.name = :root

    def output_file(entry)
      basename = File.basename entry.file,
        Lifer::Utilities.file_extension(entry.file)

      Pathname "#{basename}.html"
    end
  end
end
