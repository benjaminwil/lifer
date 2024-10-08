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
    raise NotImplementedError, I18n.t("shared.not_implemented_method")
  end

  self.name = :uri_strategy
end

require_relative "uri_strategy/pretty"
require_relative "uri_strategy/simple"
