require "optparse"

require "lifer/dev/server"

module Lifer
  class CLI
    # This constant tracks the supported Lifer CLI subcommands. Key: name;
    # value: description.
    SUBCOMMANDS = {
      build:
        "Build the Lifer project as configured in your Lifer configuration " \
        "file.",
      help:
        "Display help text for the Lifer commandline interface.",
      serve:
        "Run a Lifer development server. (http://localhost:9292 by default.)"
   }

    class << self
      # This method parses the given CLI subcommands and arguments, and then
      # starts the Lifer program as requested.
      #
      # @return [void]
      def start! = self.new.start!
    end

    attr_accessor :args, :subcommand, :parser

    def initialize
      @subcommand, @args = user_input
      @parser =
        OptionParser.new do |parser|
          parser.banner = ERB.new(<<~BANNER).result
            Lifer, the static site generator. Usage: lifer [subcommand] [options]

            Subcommands:
              <%= Lifer::CLI::SUBCOMMANDS
                .map { [Lifer::Utilities.bold_text(_1), _2].join(": ") }
                .join("\n  ") %>
          BANNER
        end
    end

    def start!
      case subcommand
      when :build then parser.parse!(args) && Lifer.build!
      when :help then parser.parse!(["--help"])
      when :serve then parser.parse!(args) && Lifer::Dev::Server.start!
      else
        puts "%s is not a supported subcommand. Running %s instead." % [
          Lifer::Utilities.bold_text(subcommand),
          Lifer::Utilities.bold_text("lifer build"),
        ]
        parser.parse!(args) && Lifer.build!
      end
    end

    private

    # @private
    # Pre-parse the given CLI arguments to check for subcommands.
    #
    def user_input
      return [:build, ARGV] if ARGV.empty?
      return [:build, ARGV] if ARGV.first.start_with?("-")

      [ARGV.first.to_sym, ARGV[1..]]
    end
  end
end
