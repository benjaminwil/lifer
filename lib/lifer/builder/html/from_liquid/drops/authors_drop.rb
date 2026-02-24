module Lifer::Builder::HTML::FromLiquid::Drops
  class AuthorDrop < Liquid::Drop
    attr_accessor :lifer_author

    def initialize(lifer_author) = (@lifer_author = lifer_author)

    def avatar = (@avatar ||= lifer_author.avatar)

    def name = (@name ||= lifer_author.name)

    def url = (@url ||= lifer_author.url)

    def entries
      @entries ||= lifer_author.entries.map {
        EntryDrop.new _1, collection: _1.collection, tags: _1.tags
      }
    end
  end

  class AuthorsDrop < Liquid::Drop
    attr_accessor :authors

    def initialize(lifer_authors)
      @authors = lifer_authors.map { AuthorDrop.new _1 }
    end

    def each(&block)
      authors.each(&block)
    end

    def to_a = @authors
  end
end
