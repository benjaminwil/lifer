module Lifer::Builder::HTML::FromLiquid::Drops
  # This drop represents a Lifer entry and allows users to access entry
  # metadata and content in Liquid templates.
  #
  # @example Usage
  #     <h1>{{ entry.title }}</h1>
  #     <small>Published on <datetime>{{ entry.date }}</datetime></small>
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

    # The entry date (as a string).
    #
    # @return [String]
    def date = (@date ||= lifer_entry.date)

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

    # The summary of the entry.
    #
    # @return [String] The summary of the entry.
    def summary = (@summary ||= lifer_entry.summary)

    # The entry title.
    #
    # @return [String] The entry title.
    def title = (@title ||= lifer_entry.title)
  end
end
