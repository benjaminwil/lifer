module Lifer::Builder::HTML::FromLiquid::Drops
  # This drop allows users to iterate over their Lifer tags in Liquid
  # templates.
  #
  # @example Usage
  #     {% for tag in tags %}
  #       {{ tag.name }}
  #     {% endfor %}
  #
  #     {% for entry in tags.name-of-tag.entries %}
  #       {{ entry.title }}
  #     {% endfor %}
  #
  class TagsDrop < Liquid::Drop
    attr_accessor :tags

    def initialize
      @tags = Lifer.tags.map { TagDrop.new _1 }
    end

    # Allow tags to be iterable in Liquid templates.
    #
    # @yield [CollectionDrop] All available collection drops.
    def each(&block) = tags.each(&block)

    # Allow tags to be rendered as an array in Liquid templates.
    #
    # @return [Array]
    def to_a = @tags

    # Dynamically define Liquid accessors based on the Lifer project's
    # collection names.
    #
    # @example Get the "tagName" tag's entries.
    #    {{ tags.tagName.entries }}
    #
    # @param arg [String] The name of a collection.
    # @return [CollectionDrop, NilClass]
    def liquid_method_missing(arg)
      tags.detect { arg.to_s == _1.name.to_s }
    end
  end
end
