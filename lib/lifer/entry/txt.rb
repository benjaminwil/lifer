class Lifer::Entry::TXT < Lifer::Entry
  self.include_in_feeds = false
  self.input_extensions = ["txt"]
  self.output_extension = :txt

  # FIXME: This could probably get more sophisticated, but at the moment HTML
  # entries don't have any way to provide metadata about themselves. So let's
  # just give them a default date to start.
  #
  # @return [Time] The publication date of the HTML entry.
  def date = Lifer::Entry::DEFAULT_DATE

  # Since text  entries cannot provide metadata about themselves, we must extract
  # a title from the permalink. Depending on the filename and URI strategy being
  # used for the collection, it's possible that the extracted title would be
  # "index", which is not very descriptive. If that's the case, we attempt to go
  # up a directory to find a "non-index" title.
  #
  # @return [String] The extracted title of the entry.
  def title
    candidate = File.basename(permalink, ".txt")

    if candidate.include?("index") && !file.to_s.include?("index")
      File.basename(permalink.sub(/\/#{candidate}\.html$/, ""))
    else
      candidate
    end
  end

  def to_html = full_text
end