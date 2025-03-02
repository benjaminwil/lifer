require "listen"
require "puma"
require "puma/configuration"
require "rack"

require_relative "router"

# This module namespace contains development mode resources for Lifer. This
# functionality is subject to immense change and generally is not safe to use in
# production environment.
#
module Lifer::Dev
  # This server is used in development and test modes to preview and serve a
  # Lifer project. It's for convenience and is not super sophisticated. The
  # server wraps a Puma process with some reasonable, default settings. It also
  # listens for file changes and rebuilds the project on the next request made to
  # the web server.
  #
  class Server
    # The default port to run the Puma server on.
    #
    DEFAULT_PORT = 9292

    class << self
      # Start a Puma server to preview your Lifer project locally.
      #
      # @param port [Integer] The port to start the Puma server with.
      # @return [void] The foregrounded Puma process.
      def start!(port:)
        puma_configuration = Puma::Configuration.new do |config|
          config.app rack_app
          config.bind "tcp://127.0.0.1:#{port || DEFAULT_PORT}"
          config.environment "development"
          config.log_requests true
        end

        Lifer.build!(environment: :serve)

        listener.start

        Puma::Launcher.new(puma_configuration).run
      end

      # A proc that follows the [Rack server specification][1]. Because we don't
      # want to commit a rackup configuration file at this time, any "middleware"
      # we want to insert should be a part of this method.
      #
      # [1]: https://github.com/rack/rack/blob/main/SPEC.rdoc
      #
      # @return [Array] A Rack server-compatible array.
      def rack_app
        -> (env) {
          reload!
          router.response_for(env)
        }
      end

      private

      # @private
      # We notify the dev server whether there are changes within the Lifer root
      # using a Listener callback method.
      #
      def listener
        @listener ||=
          Listen.to(Lifer.root) do |modified, added, removed|
            @changes = true
          end
      end

      # @private
      # On reload, we rebuild the Lifer project.
      #
      # @fixme Partial rebuilds would be a nice enhancement for performance
      #   reasons.
      #
      def reload!
        if @changes
          Lifer.build!

          @changes = false
        end
      end

      # @private
      # @return [Lifer::Dev::Router] Our dev server router.
      def router
        return @router if @router && !test_mode?

        @router = Lifer::Dev::Router.new build_directory: Lifer.output_directory
      end

      def test_mode? = ENV["LIFER_ENV"] == "test"
    end
  end
end
