class Lifer::URIStrategy::Pretty < Lifer::URIStrategy
  self.name = :pretty

  def output_file(entry)
    basename = File.basename entry.file,
      Lifer::Utilities.file_extension(entry.file)

    Pathname entry.file.to_s
      .gsub(/#{root}[\/]{0,1}/, "")
      .gsub(/#{basename}(\..+)/, "#{basename}/index.#{file_extension(entry)}")
  end
end
