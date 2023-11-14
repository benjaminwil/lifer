class Lifer::Builder
  class << self
    attr_accessor :name

    def all
      descendants.map(&:name)
    end

    def build!(*builder_names, root:)
      builder_names.each do |builder|
        Lifer::Builder.find(builder).execute root: root
      end
    end

    def find(name)
      result = descendants.detect { |descendant| descendant.name == name.to_sym }

      raise StandardError, "no builder with name \"%s\"" % name if result.nil?
      result
    end

    private

    def descendants
      ObjectSpace.each_object(Class).select { |klass| klass < self }
    end
  end

  self.name = :builder
end

require_relative "builder/rss"
require_relative "builder/simple_html_from_erb"
