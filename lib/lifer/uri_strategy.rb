class Lifer::URIStrategy
  include Lifer::Shared::FinderMethods

  class << self
    attr_accessor :name
  end

  attr_reader :root

  def initialize(root:)
    @root = root
  end

  def output_file(entry)
    raise NotImplementedError, "implement on a subclass"
  end

  self.name = :uri_strategy
end

require_relative "uri_strategy/pretty"
require_relative "uri_strategy/simple"
