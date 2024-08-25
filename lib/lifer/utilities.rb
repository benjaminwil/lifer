module Lifer::Utilities
  class << self
    # Output a string using bold escape sequences to the output TTY text.
    #
    # @param string [String] The string to display in bold.
    # @return [String] The string, but in bold.
    def bold_text(string)
      "\e[1m#{string}\e[0m"
    end

    # Given a string path, classify it into a namespaced Ruby constant. If the
    # constant does not exist, we raise a helpful error. For example:
    #
    #    Given:  my/class_name/that_exists
    #    Result: My::ClassName::ThatExists
    #
    # FIXME:
    # Note that this method is currently a bit naive. It cannot politely
    # transform classes with many caps in them (i.e. `URIStrategy`) without
    # being given an exact match (`URIStrategy`) or a broken-looking one
    # (`u_r_i_strategy`).
    #
    # @param string_constant [String] A string that maps to a Ruby constant.
    # @return [Class, Module]
    # @raise [RuntimeError]
    def classify(string_constant)
      Object.const_get camelize(string_constant)
    rescue NameError => exception
      raise "could not find constant for path \"#{string_constant}\" " \
        "(#{camelize(string_constant)})"
    end

    # Given a path, figure out what the extension is. It supports
    # multi-extensions like ".html.erb".
    #
    # @param path [Pathname, String] The path to a file.
    # @return [String] The extension (i.e. ".html.erb").
    def file_extension(path)
      File.basename(path.to_s.downcase).match(/(?<=.)\..*/).to_s
    end

    def symbolize_keys(hash)
      symbolized_hash = {}

      hash.each do |key, value|
        symbolized_hash[(key.to_sym rescue key) || key] =
          value.is_a?(Hash) ? symbolize_keys(value) : value

        symbolize_keys(value) if value.is_a?(Hash)
      end

      symbolized_hash
    end

    private

    def camelize(string)
      string = string.to_s
      string
        .gsub("/", "::")
        .split("::")
        .map(&:capitalize)
        .map { |mod| mod.split("_").map(&:capitalize).join }
        .join("::")
    end
  end
end
