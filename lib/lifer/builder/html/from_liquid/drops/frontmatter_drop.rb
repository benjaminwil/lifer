module Lifer::Builder::HTML::FromLiquid::Drops
  # Markdown entries may contain YAML frontmatter. And if they do, we need a way
  # for the Liquid templates to access that data.
  #
  # Example usage:
  #
  #     {{ entry.frontmatter.any_available_frontmatter_key }}
  #
  class FrontmatterDrop < Liquid::Drop
    def initialize(entry)
      @frontmatter = Lifer::Utilities.stringify_keys(entry.frontmatter)
    end

    # Ensure that the frontmatter can be output wholly into a rendered template
    # if need be.
    #
    # @return [String]
    def to_s = frontmatter.to_json

    # Dynamically define Liquid accessors based on the Lifer settings object.
    # For example, to get a collections URI strategy:
    #
    #    {{ settings.my_collection.uri_strategy }}
    #
    # @param arg [String] The name of a collection.
    # @return [CollectionDrop, NilClass]
    def liquid_method_missing(arg)
      value = frontmatter[arg]

      if value.is_a?(Hash)
        as_drop(value)
      elsif value.is_a?(Array) && value.all? { _1.is_a?(Hash) }
        value.map { as_drop(_1) }
      else
        value
      end
    end

    private

    attr_reader :frontmatter

    def as_drop(hash) = self.class.new(hash)
  end
end
