module Lifer::CLI
  class ArgumentExecutor
    class << self
      # Given a hash of CLI arguments, process each argument and perform any
      # setup logic that they represent.
      #
      # @param args [Hash] A hash that represent's the user's input CLI
      #   arguments.
      # @return [void]
      def execute!(args: {})
        in_priority_order(args).each do |param, value|
          parameter_for(param)
            &.public_send(:[], :method, *values_from(value))
            &.call
        end
      end

      private

      # @private
      # Reorder the list of arguments. Ensure that `--help` and `-h` are
      # processed first.
      #
      # @param args [Hash]
      # @return [Hash]
      def in_priority_order(args)
        args.sort_by { |arg|
          Lifer::CLI::HELP_PARAMETERS.any? { |param| arg == param }
        }
      end

      # @private
      # Whether the arguments contain parameters (`--help`) or short parameters
      # (`-h`), ensure the correct metadata for the parameter is available and
      # return it.
      #
      # @param param [Symbol] A parameter or short parameter name.
      # @return [Hash, NilClass] Either a hash of data that described the
      #   parameter functionality or nil for unregistered parameters.
      def parameter_for(param)
        Lifer::CLI::PARAMETERS[param] ||
          Lifer::CLI::PARAMETERS[Lifer::CLI::SHORT_PARAMETERS[param]]
      end

      # @private
      # Since parameters are represented as key-value pairs, the value side
      # could be `true`, or any other value. If it's `true` we know it doesn't
      # need to be passed down to any further methods, but any other value should
      # be iterable.
      #
      # @param value [TrueClass, FalseClass, String, Array] A value that
      #   represents the parameter's user-input value.
      # @return [Array]
      def values_from(value)
        return [] if value.class == TrueClass

        Array(value)
      end
    end
  end
end
