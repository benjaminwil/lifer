module Lifer::Dev
  # This class is responsible for building Rack-compatible responses for the
  # `Lifer::Dev::Server`. This code would never be run in a production
  # environment, where the Lifer builders are concerned.
  #
  class Response
    attr_accessor :path

    # Builds a single, Rack-compatible response object.
    #
    # @param path [String] A path URI.
    # @return [void]
    def initialize(path)
      @path = path
    end

    # The Rack-compatible response. That's an array with three items:
    #
    #   1. The HTTP status.
    #   2. The HTTP headers.
    #   3. The HTTP body response.
    #
    # @return [Array] A Rack-compatible response.
    def build
      [status, {"Content-Type": content_type}, contents]
    end

    private

    def contents
      return [I18n.t("dev.router.four_oh_four")] unless File.exist?(path)

      [File.read(path)]
    end

    # @fixme  It would be very nice to not manually manage this list of
    #   content types. Is there a nice, dependency-free way to do this?
    #
    def content_type
      case File.extname(path)
      when ".css" then "text/css"
      when ".html" then "text/html"
      when ".ico" then "image/ico"
      when ".js" then "text/javascript"
      when ".map" then "application/json"
      when ".txt" then "text/plain"
      when ".woff" then "application/font-woff2"
      when ".woff2" then "application/font-woff2"
      when ".xml" then "application/xml"
      else
        raise NotImplementedError,
          I18n.t("dev.router.content_type_not_implemented", path:)
      end
    end

    def status
      File.exist?(path) ? 200 : 404
    end
  end
end
