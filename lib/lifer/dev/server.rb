require "puma"
require "puma/configuration"
require "rack"

require_relative "router"

module Lifer::Dev
  class Server
    DEFAULT_PORT = 9292

    class << self
      # Start a Puma server to preview your Lifer project locally.
      #
      # @param port [Integer] The port to start the Puma server with.
      # @return [void] The foregrounded Puma process.
      def start!(port: DEFAULT_PORT)
        puma_configuration = Puma::Configuration.new do |config|
          config.app rack_app
          config.bind "tcp://127.0.0.1:#{port}"
          config.environment "development"
        end

        Puma::Launcher.new(puma_configuration).run
      end

      def rack_app
        -> (env) { router.response_for(env) }
      end

      private

      def router
        @router ||=
          Lifer::Dev::Router.new(build_directory: Lifer.output_directory)
      end
    end
  end
end
