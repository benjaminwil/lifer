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
    def build = [status, {"Content-Type": content_type}, contents]

    private

    def contents
      return [I18n.t("dev.router.four_oh_four")] unless File.exist?(path)

      [File.read(path)]
    end


    # The MIME type for the current path. Because Lifer only offers a server
    # for development mode, this is just a simple map based on common known
    # MIME types. We recommend submitting a patch or monkey-patching this
    # method if it does not suit your needs in development. For more
    # information:
    #
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/MIME_types/Common_types
    #
    # @fixme It would be very nice to not manually manage this list of
    #   content types. Is there a nice, dependency-free way to do this?
    #
    # @return [String] The MIME type for the current  path's file extension.
    def content_type
      case File.extname(path)
      when ".aac" then "audio/aac"
      when ".apng" then "image/apng"
      when ".avi" then "video/x-msvideo"
      when ".avif" then "image/avif"
      when ".bin" then "application/octet-stream"
      when ".bmp" then "image/bmp"
      when ".css" then "text/css"
      when ".csv" then "text/csv"
      when ".epub" then "application/epub+zip"
      when ".gz" then "application/gzip"
      when ".gif" then "image/gif"
      when ".html" then "text/html"
      when ".ico" then "image/ico"
      when ".ics" then "text/calendar"
      when ".jpeg", ".jpg" then "image/jpg"
      when ".js" then "text/javascript"
      when ".json" then "application/json"
      when ".jsonld" then "application/ld+json"
      when ".mid", ".midi" then "audio/midi"
      when ".map" then "application/json"
      when ".mpkg" then "application/vnd.apple.installer+xml"
      when ".mp3" then "audio/mpeg"
      when ".mp4" then "video/mp4"
      when ".mpeg" then "video/mpeg"
      when ".oga" then "audio/ogg"
      when ".ogv" then "video/ogg"
      when ".ogx" then "application/ogg"
      when ".opus" then "audio/ogg"
      when ".otf" then "font/otf"
      when ".pdf" then "application/pdf"
      when ".png" then "image/png"
      when ".rar" then "application/vnd.rar"
      when ".rtf" then "application/rtf"
      when ".sh" then "application/x-sh"
      when ".svg" then "image/svg+xml"
      when ".tar" then "application/x-tar"
      when ".tif", ".tiff" then "image/tiff"
      when ".ttf" then "font/tff"
      when ".txt" then "text/plain"
      when ".wav" then "audio/wav"
      when ".weba" then "audio/webm"
      when ".webm" then "video/webm"
      when ".webmanifest" then "application/manifest+json"
      when ".webp" then "image/webp"
      when ".woff", ".woff2" then "application/font-woff2"
      when ".xml" then "application/xml"
      when ".xhtml" then "application/xhtml+xml"
      when ".xml" then "application/xml"
      when ".xul" then "application/vnd.mozilla.xul+xml"
      when ".zip" then "application/zip"
      when ".7z" then "application/x-7z-compressed"
      else
        raise NotImplementedError,
          I18n.t("dev.router.content_type_not_implemented", path:)
      end
    end

    def status = File.exist?(path) ? 200 : 404
  end
end
