require "optparse"

require "lifer/dev/server"

module Lifer
  class CLI
    # The core CLI help text lives in a template file.
    #
    BANNER_ERB =
      File.read("%s/lib/lifer/templates/cli.txt.erb" % Lifer.gem_root)

    # This constant tracks the supported Lifer CLI subcommands.
    #
    #   Key: name
    #   Value: description
    #
    SUBCOMMANDS = {
      build: I18n.t("cli.subcommands.build"),
      help: I18n.t("cli.subcommands.help"),
      serve: I18n.t("cli.subcommands.serve")
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
          parser.banner = ERB.new(BANNER_ERB).result

          parser.on "-cCONFIG", "--config=CONFIG", topt(:config) do |config|
            @config_file = config
          end

          parser.on "-d", "--dump-default-config", topt(:dump_default_config) do |_|
            puts File.read(Lifer::Config::DEFAULT_CONFIG_FILE)
            exit
          end

          parser.on "-pPORT", "--port=PORT", topt(:port) do |port|
            @dev_server_port = Integer port
          rescue => exception
            raise I18n.t("cli.bad_port", exception:)
          end

          parser.on "-rROOT", "--root=ROOT", topt(:root) do |root|
            @root = root
          end
        end
    end

    def start!
      parser.parse! args

      Lifer.brain(**{root: @root, config_file: @config_file}.compact)

      case subcommand
      when :build then Lifer.build!
      when :help then parser.parse!(["--help"])
      when :serve then Lifer::Dev::Server.start!(port: @dev_server_port)
      else
        puts I18n.t(
          "cli.no_subcommand",
          subcommand: Lifer::Utilities.bold_text(subcommand),
          default_command: Lifer::Utilities.bold_text("lifer build")
        )

        parser.parse!(args) && Lifer.build!
      end
    end

    private

    # @private
    # Convenience method to get translated option documentation.
    #
    def topt(i18n_key)
      I18n.t("cli.options.#{i18n_key}")
    end

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
