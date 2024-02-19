# This pseudo-collection provides a list of all Markdown entries from all
# collections.
#
# To provide this to Lifer, configure it in your pseudo collections:
#
#     global:
#       pseudo_collections:
#         - lifer/collection/pseudo/all_markdown
#
class Lifer::Collection::Pseudo::AllMarkdown < Lifer::Collection::Pseudo
  def entries
    Lifer::Entry::Markdown.manifest
  end
end
