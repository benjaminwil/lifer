module Lifer::Builder::HTML::FromLiquid::Drops
  # This drop allows users to access Lifer tag information from within
  # Liquid templates.
  #
  # @example Usage
  #     {{ tag.name }}
  #     {% for entries in tag.entries %}
  #       {{ entry.title }}
  #     {% endfor %}
  #
  class TagDrop < Liquid::Drop
    attr_accessor :lifer_tag

    def initialize(lifer_tag) = (@lifer_tag = lifer_tag)

    # The tag name.
    #
    # @return [Symbol]
    def name = (@name ||= lifer_tag.name)

    # Gets all entries in a tag and converts them to entry drops that can
    # be accessed in Liquid templates. Example:
    #
    #     {% for entry in tags..entries %}
    #       {{ entry.title }}
    #     {% endfor %}
    #
    # @return [Array<EntryDrop>]
    def entries
      @entries ||= lifer_tag.entries.map { |lifer_entry|
        EntryDrop.new lifer_entry,
          collection: CollectionDrop.new(lifer_entry.collection),
          tags: lifer_entry.tags.map { TagDrop.new _1 }
      }
    end

    # The tag's layout file path.
    #
    # @return [String] The path to the layout file.
    def layout_file = (@lifer_tag.layout_file)
  end
end
