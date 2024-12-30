# The default URI strategy. It simply takes an input filename (i.e. "entry.md")
# and outputs a mirrorring output filename with the correct output format (i.e.
# "entry.html").
#
class Lifer::URIStrategy::Simple < Lifer::URIStrategy
  self.name = :simple

  # @see Lifer::URIStrategy#output_file
  def output_file(entry)
    basename = File.basename entry.file,
      Lifer::Utilities.file_extension(entry.file)

    Pathname entry.file.to_s
      .gsub(/#{root}[\/]{0,1}/, "")
      .gsub(/#{basename}(\..+)/, "#{basename}.#{file_extension(entry)}")
  end
end
