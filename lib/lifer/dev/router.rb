require_relative "response"

module Lifer::Dev
  # The dev router is responsible for routing requests from the
  # `Lifer::Dev:Server`. Note that in production, the dev server would never be
  # used. So the dev router does not need to be very sophisticated.
  #
  class Router
    attr_accessor :build_directory

    # Builds an instance of the router. In development mode, we'd expect only
    # one router to be initialized, but in test mode, there'd be a new one for
    # each test.
    #
    # @param build_directory [String] The path to the Lifer output directory
    #   (i.e. `/path/to/_build`).
    # @return [void]
    def initialize(build_directory:)
      @build_directory = build_directory
    end

    # Give a Rack request env object, return a Rack-compatible response.
    #
    # @param request_env [Hash] A Rack request env object.
    # @return [Lifer::Dev::Response]
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
