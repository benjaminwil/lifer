class Lifer::Builder
  class HTML
    # A base class for all HTML builder adapters. The methods provided by this
    # class are either required or reusable by builder subclasses. See the
    # committed HTML builder adapter classes for example implementations.
    class FromAny
      class << self
        # Build and render an entry.
        #
        # @param entry [Lifer::Entry] The entry to be rendered.
        # @return [String] The rendered entry.
        def build(entry:)
          new(entry: entry).build
        end
      end

      # The base class does not provide a render method, but any subclass
      # should be expected to.
      #
      # @raise [NotImplementedError]
      def render
        raise NotImplementedError,
          "subclasses must implement a custom `#render` method"
      end

      private

      # The frontmatter provided by the layout file.
      #
      # @return [Hash] The frontmatter represented as a hash.
      def frontmatter
        return {} unless frontmatter?

        Lifer::Utilities.symbolize_keys(
          YAML.load layout_file_contents(raw: true)[Lifer::FRONTMATTER_REGEX, 1],
            permitted_classes: [Time]
        )
      end

      # Checks whether frontmatter is present in the layout file.
      #
      # @return [boolean]
      def frontmatter?
        @frontmatter ||=
          layout_file_contents(raw: true).match?(Lifer::FRONTMATTER_REGEX)
      end

      # The contents of the layout file.
      #
      # @param raw [boolean] Whether to include or exclude frontmatter from
      #   the contents.
      # @return [String] The contents of the layout file.
      def layout_file_contents(raw: false)
        cache_variable = "@layout_file_contents_#{raw}"
        cached_value = instance_variable_get cache_variable

        return cached_value if cached_value

        contents = File.read layout_file
        contents = contents.gsub(Lifer::FRONTMATTER_REGEX, "") unless raw

        instance_variable_set cache_variable, contents
      end
    end
  end
end
