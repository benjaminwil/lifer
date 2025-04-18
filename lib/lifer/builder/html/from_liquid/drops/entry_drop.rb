module Lifer::Builder::HTML::FromLiquid::Drops
  # This drop represents a Lifer entry and allows users to access entry
  # metadata and content in Liquid templates.
  #
  # @example Usage
  #     <h1>{{ entry.title }}</h1>
  #     <small>
  #       Published on <datetime>{{ entry.published_at }}</datetime>
  #     </small>
  #
  class EntryDrop < Liquid::Drop
    attr_accessor :lifer_entry, :collection

    def initialize(lifer_entry, collection:, tags:)
      @lifer_entry = lifer_entry
      @collection = collection
      @tags = tags
    end

    # The entry author (or authors).
    #
    # @return [String]
    def author = authors

    # The entry authors (or author).
    #
    # @return [String]
    def authors = (@authors ||= lifer_entry.authors.join(", "))

    # The entry content.
    #
    # @return [String]
    def content = (@content ||= lifer_entry.to_html)

    # The entry frontmatter data.
    #
    # @return [FrontmatterDrop]
    def frontmatter = (@frontmatter ||= FrontmatterDrop.new(lifer_entry))

    # The path to the entry.
    #
    # @return [String] The path to the entry.
    def path = (@path ||= lifer_entry.path)

    # The entry permalink.
    #
    # @return [String] The entry permalink.
    def permalink = (@permalink ||= lifer_entry.permalink)

    # The entry publication date (as a string).
    #
    # @return [String]
    def published_at = (@published_at ||= lifer_entry.published_at)

    # The summary of the entry.
    #
    # @return [String] The summary of the entry.
    def summary = (@summary ||= lifer_entry.summary)

    # The entry title.
    #
    # @return [String] The entry title.
    def title = (@title ||= lifer_entry.title)

    # The entry's last updated date (as a string).
    #
    # @return [String]
    def updated_at = (@updated_at ||= lifer_entry.updated_at)
  end
end
