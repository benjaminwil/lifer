module Lifer
  module CLI
    SUBCOMMANDS = [:build, :help, :serve]
    PARAMETERS = [
      :h, :help
    ]
  end
end

require_relative "cli/argument_parser"
