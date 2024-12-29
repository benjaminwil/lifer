# This drop represents a Lifer entry and allows users to access entry metadata
# and content in Liquid templates. Example:
#
#     <h1>{{ entry.title }}</h1>
#     <small>Published on <datetime>{{ entry.date }}</datetime></small>
#
module Lifer::Builder::HTML::FromLiquid::Drops
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
end
