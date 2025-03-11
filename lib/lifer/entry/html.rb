# If the entry input is mainly HTML, then this subclass should track it and
# define its functionality. That means HTML files, and any file that compiles
# into an HTML file.
#
class Lifer::Entry::HTML < Lifer::Entry
  self.include_in_feeds = false
  self.input_extensions = ["html", "html.erb", "html.liquid"]
  self.output_extension = :html

  # If there is no available metadata in the HTML file, we can extract a
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
  def to_html = body
end
