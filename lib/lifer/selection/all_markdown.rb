# This selection provides a list of all Markdown entries from all
# collections.
#
# To provide this to Lifer, configure it in your selections:
#
#     selections:
#       - lifer/selection/all_markdown
#
class Lifer::Selection::AllMarkdown < Lifer::Selection
  self.name = :all_markdown

  def entries
    Lifer::Entry::Markdown.manifest
  end
end
