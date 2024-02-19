class Lifer::Collection::Pseudo < Lifer::Collection
  class << self
    attr_accessor :name

    def generate
      new(name: name, directory: nil)
    end

    private

    def inherited(klass)
      klass.name ||= :unnamed_pseudo_collection
    end
  end

  def entries
    raise NotImplementedError,
      "all pseudo collections must implement `#entries`"
  end

  def setting(...)
    super(...)
  end

  private

  def layout_file
  end

  self.name = :pseudo_collection
end

require_relative "pseudo/all_markdown"
require_relative "pseudo/included_in_feeds"
