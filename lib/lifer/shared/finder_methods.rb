# This module provides simple finder methods to classes that need to keep track
# of their descendant classes.
#
# @example Usage
#     class MyClass
#       included Lifer::Shared::FinderMethods
#       # ...
#     end
#
module Lifer::Shared::FinderMethods
  # @!visibility private
  def self.included(klass)
    klass.extend ClassMethods
  end

  # This module contains the class methods to be included in other classes.
  #
  module ClassMethods
    # A simple finder.
    #
    # @param name [string] The configured name of the builder you want to find.
    # @return [Class] A builder class.
    def find(name)
      result = subclasses.detect { |klass| klass.name == name.to_sym }

      if result.nil?
        raise StandardError, I18n.t("shared.finder_methods.unknown_class", name:)
        return
      end

      result
    end
  end
end
