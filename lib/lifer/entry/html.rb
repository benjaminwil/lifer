class Lifer::Entry::HTML < Lifer::Entry
  self.include_in_feeds = false
  self.input_extensions = ["html", "html.erb", "html.liquid"]
  self.output_extension = :html

  # FIXME: This could probably get more sophisticated, but at the moment HTML
  # entries don't have any way to provide metadata about themselves. So let's
  # just give them a default date to start.
  #
  # @return [Time] The publication date of the HTML entry.
  def date = Lifer::Entry::DEFAULT_DATE

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
