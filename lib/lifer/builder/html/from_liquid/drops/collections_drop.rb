module Lifer::Builder::HTML::FromLiquid::Drops
  # This drop allows users to iterate over their Lifer collections in Liquid
  # templates.
  #
  # @example Usage
  #     {% for collection in collections %}
  #       {{ collection.name }}
  #     {% endfor %}
  #
  class CollectionsDrop < Liquid::Drop
    attr_accessor :collections

    def initialize
      @collections = Lifer.collections.map { CollectionDrop.new _1 }
    end

    # Allow collections to be iterable in Liquid templates.
    #
    # @yield [CollectionDrop] All available collection drops.
    def each(&block)
      collections.each(&block)
    end

    # Allow collections to be rendered as an array in Liquid templates.
    #
    # @return [Array]
    def to_a = @collections

    # Dynamically define Liquid accessors based on the Lifer project's
    # collection names.
    #
    # @example Get the root collection's name.
    #    {{ collections.root.name }}
    #
    # @param arg [String] The name of a collection.
    # @return [CollectionDrop, NilClass]
    def liquid_method_missing(arg)
      collections.detect { arg.to_sym == _1.name }
    end
  end
end
