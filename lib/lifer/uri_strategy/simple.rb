class Lifer::URIStrategy::Simple < Lifer::URIStrategy::Base
  def name_for(entry)
    File.basename(entry.file, ".*")
  end

  def dirname_for(entry)
    return nil if (path = entry.file.dirname.to_s) == directory.to_s

    Pathname entry.file.dirname.to_s.gsub(
      /#{directory}[\/]{0,1}/,
      ""
    )
  end

  def file_for(entry)
    Pathname(
      [
        dirname_for(entry),
        ("%s.html" % name_for(entry))
      ].compact.join("/")
    )
  end
end
