class Lifer::Builder
  class << self
    def find(name)
      result = descendants.detect { |descendant| descendant.name == name }

      raise StandardError, "no builder with name \"%s\"" % name if result.nil?
      result
    end

    def name
      super.split("::").last.downcase.to_sym
    end

    private

    def descendants
      ObjectSpace.each_object(Class).select { |klass| klass < self }
    end
  end
end

require_relative "builder/html"
require_relative "builder/rss"
