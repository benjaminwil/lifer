# One may want to provide browser-readable text files without any layout or
# metadata information. In those cases, here's a good entry subclass. Just make
# sure the entry ends in `.txt`.
#
class Lifer::Entry::TXT < Lifer::Entry
  self.include_in_feeds = false
  self.input_extensions = ["txt"]
  self.output_extension = :txt

  # If there is no available metadata in the text file, we can extract a
  # makeshift title from the permalink.
  #
  # Depending on the filename and URI strategy being used for the collection,
  # it's possible that the extracted title would be "index", which is not very
  # descriptive. If that's the case, we attempt to go up a directory to find a
  # non-"index" title.
  #
  # @return [String] The given or extracted title of the entry.
  def title
    return frontmatter[:title] if frontmatter[:title]

    candidate = File.basename(permalink, ".txt")

    if candidate.include?("index") && !file.to_s.include?("index")
      File.basename(permalink.sub(/\/#{candidate}\.html$/, ""))
    else
      candidate
    end
  end

  # While we don't actually output text to HTML, we need to implement this
  # method so that the RSS feed builder can add text files as feed entries.
  #
  # @fixme Maybe the `#to_html` methods should be renamed, then?
  #
  # @return [String] The output HTML (not actually HTML).
  def to_html = body
end
