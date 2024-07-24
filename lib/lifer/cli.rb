module Lifer
  module CLI
    SUBCOMMANDS = {
      build:
        "Build the Lifer project as configured in your Lifer configuration " \
        "file.",
      help:
        "Display help text for the Lifer commandline interface.",
      serve:
        "Run a Lifer development server. (http://localhost:9292 by default.)"
    }
    PARAMETERS = {
      help: {
        description:
          "Ignore other parameters and display help text for the Lifer " \
          "commandline interface.",
        method: -> {
          Lifer::CLI.help_text
          Lifer::CLI.exit!
        }
      }
    }
    SHORT_PARAMETERS = {
      help: :h
    }
    HELP_PARAMETERS = [:help, :h]

    class << self
      # When called, this method immediately exits the Ruby program. This
      # wrapper method basically exists to make testing the CLI easier.
      #
      # @return [void]
      def exit! = exit

      # Print help text to inform the user about the commandline interface
      # options.
      #
      # @return [void]
      def help_text
        puts <<~TXT.rstrip
          Lifer, the static site generator

          Usage:
            lifer [subcommand]

          Subcommands:
        TXT
        puts SUBCOMMANDS.map { "  %s: %s" % [_1, _2] }.join("\n")
        puts <<~TXT.rstrip

          Flags:
        TXT
        puts PARAMETERS.map { |name, info|
          "  --%s, -%s: %s" % [name, SHORT_PARAMETERS[name], info[:description]]
        }.join("\n")
      end
    end
  end
end

require_relative "cli/argument_executor"
require_relative "cli/argument_parser"
