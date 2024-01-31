# This module provides simple finder methods to classes that need to keep track
# of their descendant classes.
#
module Lifer::Shared::FinderMethods
  def self.included(klass)
    klass.extend ClassMethods
  end

  module ClassMethods
    # Get a list of all available builder subclasses.
    #
    # @return [Array<Class>] A list of all builder classes.
    def all
      descendants.map(&:name)
    end

    # A simple finder.
    #
    # @params name [string] The configured name of the builder you want to find.
    # @return [Class] A builder class.
    def find(name)
      result = descendants.detect { |descendant| descendant.name == name.to_sym }

      raise StandardError, "no class with name \"%s\"" % name if result.nil?
      result
    end

    private

    # @private
    def descendants
      ObjectSpace.each_object(Class).select { |klass| klass < self }
    end
  end
end
