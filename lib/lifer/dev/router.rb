require_relative "response"

module Lifer::Dev
  class Router
    attr_accessor :build_directory

    def initialize(build_directory:)
      @build_directory = build_directory
    end

    def response_for(request_env)
      local_path = local_path_to request_env["PATH_INFO"]

      Lifer::Dev::Response.new(local_path).build
    end

    private

    def local_path_to(requested_path)
      if requested_path.end_with?("/")
        requested_path = requested_path + "index.html"
      elsif Lifer::Utilities.file_extension(requested_path) == ""
        requested_path = requested_path + "/index.html"
      end

      "%s%s" % [build_directory, requested_path]
    end
  end
end
