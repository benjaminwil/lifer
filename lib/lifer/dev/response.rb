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

    def content_type
      case File.extname(path)
      when ".html" then "text/html"
      when ".css" then "text/css"
      when ".js" then "text/javascript"
      when ".ico" then "image/ico"
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
