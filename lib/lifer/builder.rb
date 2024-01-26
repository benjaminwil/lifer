# Builders are a core part of Lifer. Builders are configured by users in the
# configuration file and take the content of a Lifer project and turn it into
# built stuff. That could be feeds, HTML documents, or other weird files.
#
# This base class includes some special functionality for running all builders
# when a Lifer build is executed. But it also sets in stone the public API for
# implementing builder classes. (In short: an `.execute` class method and an
# `#execute` instance method.)
#
class Lifer::Builder
  class << self
    attr_accessor :name

    # Every builder class must have execute method. This is the entrypoint for
    # instantiating *and* executing any builder.
    #
    # @param root [string] An absolute path to the Lifer project root directory.
    # @return [NotImplementedError] A builder subclass must implement this
    #   method.
    def execute(root:)
      raise NotImplementedError
    end

    # Get a list of all available builder subclasses.
    #
    # @return [Array<Class>] A list of all builder classes.
    def all
      descendants.map(&:name)
    end

    # Given a list of builder names, we execute every builder based on the
    # configured Lifer project root.
    #
    # @param builder_names [<string>] A list of builder names.
    # @param root [string] The absolute path to the Lifer root directory.
    # @return [void]
    def build!(*builder_names, root:)
      builder_names.each do |builder|
        Lifer::Builder.find(builder).execute root: root
      end
    end

    # A simple finder.
    #
    # @params name [string] The configured name of the builder you want to find.
    # @return [Class] A builder class.
    def find(name)
      result = descendants.detect { |descendant| descendant.name == name.to_sym }

      raise StandardError, "no builder with name \"%s\"" % name if result.nil?
      result
    end

    private

    # @private
    def descendants
      ObjectSpace.each_object(Class).select { |klass| klass < self }
    end

  # Every builder class must have execute instance method. This is where the
  # core logic of the builder runs from after initialization.
  #
  # @return [NotImplementedError] A builder subclass must implement this
  #   method.
  def execute
    raise NotImplementedError
  end

  self.name = :builder
end

require_relative "builder/rss"
require_relative "builder/simple_html_from_erb"
