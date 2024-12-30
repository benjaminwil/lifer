class Lifer::URIStrategy
  # This URI strategy follows the "pretty" strategy of indexifying all entries
  # (i.e. `entry.md` outputs to `entry/index.html`) and ensuring that, no matter
  # what collection the entry is in, the entry is output to the root of the Lifer
  # build directory. For example:
  #
  #     subdir/entry.md ---> entry/index.html
  #
  class PrettyRoot < Lifer::URIStrategy
    self.name = :pretty_root

    # @see Lifer::URIStrategy#output_file
    def output_file(entry)
      basename = File.basename entry.file,
        Lifer::Utilities.file_extension(entry.file)

      if basename == "index"
        Pathname "index.html"
      else
        Pathname "#{basename}/index.#{file_extension(entry)}"
      end
    end
  end
end
