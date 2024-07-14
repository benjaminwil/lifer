class Lifer::Entry::HTML < Lifer::Entry
  self.include_in_feeds = false

  def title
    File.basename permalink
  end

  # As an entry subclass, this method must be implemented, even though it
  # doesn't do much here.
  #
  # @return [String]
  def to_html
    full_text
  end
end
