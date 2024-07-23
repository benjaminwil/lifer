module Lifer::Dev
  class Response
    FOUR_OH_FOUR_TEXT = "404 Not Found"
    attr_accessor :path

    def initialize(path)
      @path = path
    end

    def build
      [status, {"Content-Type": content_type}, contents]
    end

    private

    def contents
      return [FOUR_OH_FOUR_TEXT] unless File.exist?(path)

      [File.read(path)]
    end

    def content_type
      case File.extname(path)
      when ".html" then "text/html"
      when ".css" then "text/css"
      when ".js" then "text/javascript"
      when ".ico" then "image/ico"
      else
        raise NotImplementedError, "no content type defined for files like #{path} yet"
      end
    end

    def status
      File.exist?(path) ? 200 : 404
    end
  end
end
