# This selection provides a list of all entries that can be included in feeds.
#
# To provide this to Lifer, configure it in your selections:
#
#     selections:
#       - lifer/selection/included_in_feeds
#
class Lifer::Selection::IncludedInFeeds < Lifer::Selection
  self.name = :included_in_feeds

  def entries
    Lifer::Entry.manifest.select { |entry| entry.class.include_in_feeds }
  end
end
