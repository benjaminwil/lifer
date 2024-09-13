# This drop allows users to access the current Lifer project settings from
# Liquid templates. Example:
#
#     {{ settings.my_collection.uri_strategy }}
#
class SettingsDrop < Liquid::Drop
  attr_accessor :settings

  def initialize(settings = Lifer.settings)
    @settings = Lifer::Utilities.stringify_keys(settings)
  end

  def to_liquid
    settings
  end
end

# This drop represents a Lifer entry and allows users to access entry metadata
# and content in Liquid templates. Example:
#
#     <h1>{{ entry.title }}</h1>
#     <small>Published on <datetime>{{ entry.date }}</datetime></small>
#
class EntryDrop < Liquid::Drop
  attr_accessor :lifer_entry

  def initialize(lifer_entry)
    @lifer_entry = lifer_entry
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
    @entries ||= lifer_collection.entries.map { EntryDrop.new _1 }
  end
end

# This drop allows users to iterate over their Lifer collections in Liquid
# templates. Example:
#
#     {% for collection in collections %}
#       {{ collection.name }}
#     {% endfor %}
#
class CollectionsDrop < Liquid::Drop
  attr_accessor :collections

  def initialize
    @collections = Lifer.collections.map { CollectionDrop.new _1 }
  end

  def each(&block)
    collections.each(&block)
  end

  # Dynamically define Liquid accessors based on the Lifer project's collection
  # names. For example, to get the root collection's name:
  #
  #    {{ collections.root.name }}
  #
  # @param arg [String] The name of a collection.
  # @return [CollectionDrop, NilClass]
  def liquid_method_missing(arg)
    collections.detect { arg.to_sym == _1.name }
  end
end
