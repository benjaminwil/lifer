# This drop allows users to access Lifer collection information from within
# Liquid templates. Example:
#
#     {{ collection.name }}
#
#     {% for entries in collection.entries %}
#       {{ entry.title }}
#     {% endfor %}
#
class CollectionDrop < Liquid::Drop
  attr_accessor :lifer_collection

  def initialize(lifer_collection)
    @lifer_collection = lifer_collection
  end

  def name
    @name ||= lifer_collection.name
  end

  # Gets all entries in a collection and converts them to entry drops that can
  # be accessed in Liquid templates. Example:
  #
  #     {% for entry in collections.root.entries %}
  #       {{ entry.title }}
  #     {% endfor %}
  #
  # @return [Array<EntryDrop>]
  def entries
    @entries ||=
      lifer_collection.entries.map { EntryDrop.new(_1, collection: self) }
  end

  def layout_file = @lifer_collection.layout_file
end