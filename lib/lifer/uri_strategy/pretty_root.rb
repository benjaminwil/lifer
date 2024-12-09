class Lifer::URIStrategy
  class PrettyRoot < Lifer::URIStrategy
    self.name = :pretty_root

    def output_file(entry)
      basename = File.basename entry.file,
        Lifer::Utilities.file_extension(entry.file)

      if basename == "index"
        Pathname "index.html"
      else
        Pathname "#{basename}/index.html"
      end
    end
  end
end
