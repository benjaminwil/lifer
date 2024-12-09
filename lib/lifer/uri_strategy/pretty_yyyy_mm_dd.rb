class Lifer::URIStrategy::PrettyYYYYMMDD < Lifer::URIStrategy
  self.name = :pretty_yyyy_mm_dd

  DATE_SEPARATORS = "[\-\._]{1}"
  DATE_REGEXP = /\d{4}#{DATE_SEPARATORS}\d{1,2}#{DATE_SEPARATORS}\d{1,2}#{DATE_SEPARATORS}/

  def output_file(entry)
    basename = File.basename entry.file,
      Lifer::Utilities.file_extension(entry.file)

    Pathname entry.file.to_s
      .gsub(/#{root}[\/]{0,1}/, "")
      .gsub(/#{basename}(\..+)/, "#{basename}/index.html")
      .gsub(DATE_REGEXP, "")
  end
end
