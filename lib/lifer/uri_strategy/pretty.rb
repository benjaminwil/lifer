class Lifer::URIStrategy::Pretty < Lifer::URIStrategy::Base
  def name
    "pretty"
  end

  def output_file(entry)
    basename = File.basename(entry.file, ".*")

    Pathname entry.file.to_s
      .gsub(/#{root}[\/]{0,1}/, "")
      .gsub(/#{basename}(\..+)/, "#{basename}/index.html")
  end
end
