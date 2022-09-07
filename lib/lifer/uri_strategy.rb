class Lifer::URIStrategy
  class << self
    def find_by_name(name)
      self.const_get name.capitalize
    rescue NameError => error
      raise StandardError, "no URI strategy '#{name}'"
    end
  end
end

require_relative "uri_strategy/base"
require_relative "uri_strategy/pretty"
require_relative "uri_strategy/simple"
