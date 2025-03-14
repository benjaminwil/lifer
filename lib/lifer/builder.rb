require "open3"

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
  include Lifer::Shared::FinderMethods

  class << self
    attr_accessor :name, :settings

    # Every builder class must have execute method. This is the entrypoint for
    # instantiating *and* executing any builder.
    #
    # @param root [string] An absolute path to the Lifer project root
    #   directory.
    # @return [NotImplementedError] A builder subclass must implement this
    #   method.
    def execute(root:) = (raise NotImplementedError)

    # Given a list of builder names, we execute every builder based on the
    # configured Lifer project root.
    #
    # @param builder_names [Array<string>] A list of builder names.
    # @param root [string] The absolute path to the Lifer root directory.
    # @return [void]
    def build!(*builder_names, root:)
      builder_names.each do |builder|
        Lifer::Builder.find(builder).execute root: root
      end
    end

    # Given a list of prebuild commands, execute each one in the shell.
    # This is meant to be run once before `.build!` is run once.
    #
    # @param commands [Array<string>] A list of executable commands.
    # @param root [string] The absolute path to the Lifer root directory.
    # @return [void]
    def prebuild!(*commands, root:)
      commands.each do |command|
        puts command

        _stdin, stdout, stderr, _wait_thread = Open3.popen3(command)

        if (error_messages = stderr.readlines).any?
          raise error_messages.join("\n")
        end

        stdout.readlines.each { puts _1 }
      end
    rescue => exception
      raise I18n.t("builder.prebuild_failure", exception:)
    end

    private

    # @private
    # We use the `Class#inherited` hook to add functionality to our builder
    # subclasses as they're being initialized. This makes them more ergonomic to
    # configure.
    #
    # @param klass [Class] The superclass.
    # @return [void]
    def inherited(klass)
      klass.prepend InitializeBuilder

      klass.name ||= :unnamed_builder
      klass.settings ||= []
    end
  end

  # Every builder class must have execute instance method. This is where the
  # core logic of the builder runs from after initialization.
  #
  # @return [NotImplementedError] A builder subclass must implement this
  #   method.
  def execute = (raise NotImplementedError)

  # When any new builder instance is initialized, we need to ensure that any
  # settings specific to the builder are registered. We can do this automatically
  # by wrapping the `#initialize` method. This module provides the wrapper
  # functionality--we just need to ensure that this module is included.
  #
  module InitializeBuilder
    # @!visibility private
    def initialize(...)
      Lifer.register_settings(*self.class.settings) if self.class.settings.any?

      super(...)
    end
  end

  self.name = :builder
end

require_relative "builder/rss"
require_relative "builder/html"
require_relative "builder/txt"
