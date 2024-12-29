# This drop allows users to iterate over their Lifer collections in Liquid
# templates. Example:
#
#     {% for collection in collections %}
#       {{ collection.name }}
#     {% endfor %}
#
module Lifer::Builder::HTML::FromLiquid::Drops
  class CollectionsDrop < Liquid::Drop
    attr_accessor :collections

    def initialize
      @collections = Lifer.collections.map { CollectionDrop.new _1 }
    end

    def each(&block)
      collections.each(&block)
    end

    def to_a = @collections

    # Dynamically define Liquid accessors based on the Lifer project's
    # collection names. For example, to get the root collection's name:
    #
    #    {{ collections.root.name }}
    #
    # @param arg [String] The name of a collection.
    # @return [CollectionDrop, NilClass]
    def liquid_method_missing(arg)
      collections.detect { arg.to_sym == _1.name }
    end
  end
end
