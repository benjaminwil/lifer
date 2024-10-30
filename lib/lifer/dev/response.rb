module Lifer::Dev
  class Response
    attr_accessor :path

    def initialize(path)
      @path = path
    end

    def build
      [status, {"Content-Type": content_type}, contents]
    end

    private

    def contents
      return [I18n.t("dev.router.four_oh_four")] unless File.exist?(path)

      [File.read(path)]
    end

    # FIXME:
    # It would be very nice to not manually manage this list of content types.
    # Is there a nice, dependency-free way to do this?
    #
    def content_type
      case File.extname(path)
      when ".css" then "text/css"
      when ".html" then "text/html"
      when ".ico" then "image/ico"
      when ".js" then "text/javascript"
      when ".map" then "application/json"
      when ".woff" then "application/font-woff2"
      when ".woff2" then "application/font-woff2"
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
