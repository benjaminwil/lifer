class FrontmatterDrop < Liquid::Drop
  def initialize(entry)
    @frontmatter = Lifer::Utilities.stringify_keys(entry.frontmatter)
  end

  def as_drop(hash) = self.class.new(hash)

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
end

# This drop represents a Lifer entry and allows users to access entry metadata
# and content in Liquid templates. Example:
#
#     <h1>{{ entry.title }}</h1>
#     <small>Published on <datetime>{{ entry.date }}</datetime></small>
#
class EntryDrop < Liquid::Drop
  attr_accessor :lifer_entry, :collection

  def initialize(lifer_entry, collection:)
    @lifer_entry = lifer_entry
    @collection = collection
  end

  def author
    authors
  end

  def authors
    @authors ||= lifer_entry.authors.join(", ")
  end

  def content
    @content ||= lifer_entry.to_html
  end

  def date
    @date ||= lifer_entry.date
  end

  def frontmatter
    @frontmatter ||= FrontmatterDrop.new(lifer_entry)
  end

  def path
    @path ||= lifer_entry.path
  end

  def permalink
    @permalink ||= lifer_entry.permalink
  end

  def summary
    @summary ||= lifer_entry.summary
  end

  def title
    @title ||= lifer_entry.title
  end
end
