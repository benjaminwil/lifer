class Lifer::URIStrategy
  # No matter what collection an entry is in, this URI strategy ensures that the
  # entries are output to the root of the output directory (for example:
  # `_build/<your-entry>.html`, never `_build/collection_name/<your-entry>.html`.
  #
  class Root < Lifer::URIStrategy
    self.name = :root

    # @see Lifer::URIStrategy#output_file
    def output_file(entry)
      basename = File.basename entry.file,
        Lifer::Utilities.file_extension(entry.file)

      "#{basename}.#{file_extension(entry)}"
    end
  end
end
