# The pretty URI strategy ensures that all entries are indexified, making their
# URLs "pretty" in the browser. "Pretty" because browsers often do not show
# "index.html" at the end of the URL because it's implicit.
#
# For example:
#
#     entry.md ---> entry/index.html
#
class Lifer::URIStrategy::Pretty < Lifer::URIStrategy
  self.name = :pretty

  # @see Lifer::URIStrategy#output_file
  def output_file(entry)
    basename = File.basename entry.file,
      Lifer::Utilities.file_extension(entry.file)

    entry.file.to_s
      .gsub(/#{root}[\/]{0,1}/, "")
      .gsub(/#{basename}(\..+)/, "#{basename}#{pretty_part entry}")
  end

  private

  def pretty_part(entry) = "/index.#{file_extension(entry)}"
end
