# This URI strategy ensures that entries with dates in the filename (i.e.
# `1990-12-12-my-trip-to-hamilton.md`) will always be have output filenames
# without the date included. It also follows the "pretty" URI strategy of
# outputting each file to an `index` file in a subdirectory.
#
# For example:
#
#     1990-12-12-my-trip-to-hamilton.md ---> my-trip-to-hamilton/index.html
#
 class Lifer::URIStrategy::PrettyYYYYMMDD < Lifer::URIStrategy
  self.name = :pretty_yyyy_mm_dd

  # We expect date separators to fall into this regular expression.
  #
  DATE_SEPARATORS = "[\-\._]{1}"

  # The date regular expression we expect entry filenames to follow.
  #
  DATE_REGEXP =
    /\d{4}#{DATE_SEPARATORS}\d{1,2}#{DATE_SEPARATORS}\d{1,2}#{DATE_SEPARATORS}/

  # @see Lifer::URIStrategy#output_file
  def output_file(entry)
    basename = File.basename entry.file,
      Lifer::Utilities.file_extension(entry.file)

    Pathname entry.file.to_s
      .gsub(/#{root}[\/]{0,1}/, "")
      .gsub(/#{basename}(\..+)/, "#{basename}/index.#{file_extension(entry)}")
      .gsub(DATE_REGEXP, "")
  end
end
