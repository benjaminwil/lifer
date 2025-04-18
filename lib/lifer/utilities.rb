require "parallel"

# A module namespace for any weird utilities that are used pseudo-globally.
# Ensure that these are actually useful globally, though. :-)
#
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
    # constant does not exist, we raise a helpful error.
    #
    # @example Result
    #    classify("my/class_name/that_exists") #=> My::ClassName::ThatExists
    #
    # @fixme Note that this method is currently a bit naive. It cannot politely
    #   transform classes with many caps in them (i.e. `URIStrategy`) without
    #   being given an exact match (`URIStrategy`) or a broken-looking one
    #   (`u_r_i_strategy`).
    #
    # @param string_constant [String] A string that maps to a Ruby constant.
    # @return [Class, Module]
    # @raise [RuntimeError]
    def classify(string_constant)
      Object.const_get camelize(string_constant)
    rescue NameError => exception
      raise I18n.t(
        "utilities.classify_error",
        string_constant:,
        camel_cased_string_constant: camelize(string_constant)
      )
    end

    # Takes a date and renders it in ISO 8601 format.
    #
    # @param datetime [Date, Time, DateTime, String] A representation of a date.
    # @return [String] An ISO 8601 representation of that date.
    def date_as_iso8601(datetime)
      return unless (data = DateTime.parse(datetime.to_s))

      data.strftime("%Y-%m-%dT%H:%M:%S%:z")
    rescue Date::Error
      nil
    end

    # Given a path, figure out what the extension is. It supports
    # multi-extensions like ".html.erb".
    #
    # @param path [Pathname, String] The path to a file.
    # @return [String] The extension (i.e. ".html.erb").
    def file_extension(path)
      File.basename(path.to_s.downcase).match(/(?<=.)\..*/).to_s
    end

    # Given any string, normalize it into a "kabab-case", single-word string.
    #
    #    Input:  "Hi, how are you?"
    #    Output: "hi-how-are-you"
    #
    # @param string [String] Any string.
    # @return [String] The kabab-cased output.
    def handleize(string) = parameterize(string, separator: "-")

    # Parallelize and fan out a collection of work in child processes. If any of
    # the child processes results in an error, we raise it and halt the program.
    #
    # @param collection [Array] A collection to operate on.
    # @yield [Object] A function to transform each collection item (in
    #   parallel).
    # @raise [Exception] Any exception thrown by a child process.
    # @return [Array] The mapped results of the operation.
    def parallelized(collection, &block)
      options = {}
      options[:in_threads] = 0 if Lifer.parallelism_disabled?

      results = Parallel.map(collection, **options) do |collection_item|
        begin
          yield collection_item
        rescue => error
          error
        end
      end

      first_error = results.detect { _1.is_a? Exception }
      raise first_error if first_error

      results
    end

    # Given a hash, take all of its keys (and sub-keys) and convert them into
    # strings.
    #
    # @param hash [Hash] Any hash.
    # @return [Hash] The hash with keys transformed to strings.
    def stringify_keys(hash)
      stringified_hash = {}

      hash.each do |key, value|
        stringified_hash[(key.to_s rescue key) || key] =
          value.is_a?(Hash) ? stringify_keys(value) : value

        stringify_keys(value) if value.is_a?(Hash)
      end

      stringified_hash
    end

    # Given a hash, take all of its keys (and sub-keys) and convert them into
    # symbols.
    #
    # @param hash [Hash] Any hash.
    # @return [Hash] The hash with keys transformed to symbols.
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

    def parameterize(string, separator: "-", preserve_case: false)
      text = string.gsub(/[^A-z0-9\-_]+/, separator)

      unless separator.nil? || separator.empty?
        re_sep = Regexp.escape(separator)
        re_duplicate_separator        = /#{re_sep}{2,}/
        re_leading_trailing_separator = /^#{re_sep}|#{re_sep}$/

        text.gsub!(re_duplicate_separator, separator)
        text.gsub!(re_leading_trailing_separator, "")
      end

      text.downcase! unless preserve_case
      text
    end
  end
end
