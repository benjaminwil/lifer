# The argument parser isn't incredibly smart. But it's smart enough to make
# sense of any arguments (even ones that don't exist within Lifer or are
# invalid-within-reason). Only Lifer subcommands require special treatment, so
# we must pass in all the available subcommands as context.
#
module Lifer::CLI
  class ArgumentParser
    attr_accessor :input, :output, :subcommand

    def initialize(input: [], subcommands: Lifer::CLI::SUBCOMMANDS)
      @subcommand =
        input.delete_at(0).to_sym if subcommand?(input[0], subcommands:)
      @input = input
      @output = Hash.new

      parse!
    end

    private

    # @private
    def parse!
      params.each do |a, b|
        next param_with_value(a) if param_with_value?(a)
        next param_without_value(a) if param_without_value?(a, next_arg: b)
        next param_and_value(a, b) if param_and_value?(a, next_arg: b)
      end
    end

    # @private
    # Because `#parse!` parses all arguments as pairs, we want to ensure the final
    # argument is always examined the *first argument* in a pair. So we put a `nil`
    # argument at the end of the arguments list.
    #
    def params
      args = input.dup << nil
      args.each_cons(2).to_a
    end

    # @private
    # Give the input argument:
    #
    #   --parameter=value
    #
    # We get in our output:
    #
    #   {parameter: "value"}
    #
    # @param arg [String]
    # @return [Hash]
    def param_with_value(arg)
      key, value = arg.split("=")
      key = key.gsub(/^[-]{1,2}/, "")
      value = strip_quotes(value)

      output[key.to_sym] = value
    end

    # @private
    # @param arg [String]
    # @return [Boolean]
    def param_with_value?(arg)
      arg.include? "="
    end

    # @private
    # Given the input argument:
    #
    #   --parameter
    #
    # We get in our output:
    #
    #   {parameter: true}
    #
    # @param arg [String]
    # @return [Hash]
    def param_without_value(arg)
      arg = arg.gsub(/^[-]{1,2}/, "")

      output[arg.to_sym] = true
    end

    # @private
    # @param arg [String]
    # @param next_arg [String]
    # @return [Boolean]
    def param_without_value?(arg, next_arg:)
      arg.start_with?("-") && (next_arg&.start_with?("-") || next_arg.nil?)
    end

    # Given the input arguments:
    #
    #   --parameter value
    #
    # We get in our output:
    #
    #   {parameter: "value"}
    #
    # @param arg_a [String]
    # @param arg_b [String]
    # @return [Hash]
    def param_and_value(arg_a, arg_b)
      arg_a = arg_a.gsub(/^[-]{1,2}/, "")
      arg_b = strip_quotes(arg_b)
      arg_b = arg_b.split(",") if arg_b&.include?(",")

      output[arg_a.to_sym] = arg_b
    end

    # @private
    # @param arg [String]
    # @param next_arg [String]
    # @return [Boolean]
    def param_and_value?(arg, next_arg:)
     arg.start_with?("-") && !next_arg.nil? && !next_arg.start_with?("-")
    end

    # @private
    # @param string [String, NilClass]
    # @return [String, NilClass]
    def strip_quotes(string)
      return if string.nil?

      %w[' "].each { string = string.delete_prefix(_1).delete_suffix(_1) }
      string
    end

    # @private
    # Checks if the first argument is a subcommand and should not be treated as
    # a regular argument.
    #
    # @param argument [String]
    # @param subcommands [Array<String, Symbol>]
    # @return [Boolean]
    def subcommand?(argument, subcommands:)
      subcommands.map(&:to_s).include? argument
    end
  end
end
