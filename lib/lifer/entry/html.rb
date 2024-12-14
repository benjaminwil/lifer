class Lifer::Entry::HTML < Lifer::Entry
  self.include_in_feeds = false

  # Since HTML entries cannot provide metadata about themselves, we must extract
  # a title from the permalink. Depending on the filename and URI strategy being
  # used for the collection, it's possible that the extracted title would be
  # "index", which is not very descriptive. If that's the case, we attempt to go
  # up a directory to find a "non-index" title.
  #
  # @return [String] The extracted title of the entry.
  def title
    candidate = File.basename(permalink, ".html")

    if candidate.include?("index") && !file.to_s.include?("index")
      File.basename(permalink.sub(/\/#{candidate}\.html$/, ""))
    else
      candidate
    end
  end

  # As an entry subclass, this method must be implemented, even though it
  # doesn't do much here.
  #
  # @return [String]
  def to_html = full_text
end
