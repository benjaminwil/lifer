# This message class lets us output rich messages to STDOUT without muddying up
# the Lifer source code with ad hoc `puts` statements. Using this interface
# helps us ensure that translations are accounted for, and it lets us format
# errors and log messages in a consistent way.
#
# If the program is in test mode, this  means the message should not be output
# to STDOUT.
#
class Lifer::Message
  ANSI_COLOURS = {red: "31"}

  class << self
    # Outputs a red error message into STDOUT for higher visibility. Note that
    # this is still just a message, and the program might not exit due to an
    # exception having been raised.
    #
    # @param translation_key [String] A translation key that can be read by the
    #   `I18n` library.
    # @param test_mode [boolean] Whether the message should be output as if the
    #   program were in test mode.
    # @parms **args [Hash] A catch-all keyword arguments to be passed on to
    #   `I18n.t!`.
    # @return [void] The message is pushed to STDOUT.
    def error(translation_key, test_mode: test_mode?, **args)
      return if test_mode

      prefix = I18n.t("message.prefix.error")
      error_message = I18n.t!(translation_key, **args)

      puts colorize(("%s: %s" % [prefix, error_message]), :red)
    end

    # Outputs a log message into STDOUT.
    #
    # @param translation_key [String] A translation key that can be read by the
    #   `I18n` library.
    # @param test_mode [boolean] Whether the message should be output as if the
    #   program were in test mode.
    # @parms **args [Hash] A catch-all keyword arguments to be passed on to
    #   `I18n.t!`.
    # @return [void] The message is pushed to STDOUT.
    def log(translation_key, test_mode: test_mode?, **args)
      return if test_mode

      puts I18n.t!(translation_key, **args)
    end

    private

    def colorize(text, ansi_colour_name)
      "\e[#{ANSI_COLOURS[ansi_colour_name]}m#{text}\e[0m"
    end

    def test_mode? = (ENV["LIFER_ENV"] == "test")
  end
end
