require "erb"

class Lifer::Builder::HTML
  class Layout
    class << self
      # Build and render an entry.
      #
      # @param entry [Lifer::Entry] The entry to be rendered.
      # @return [String] The rendered entry.
      def build(entry:)
        new(entry: entry).render
      end
    end

    # Reads the entry as ERB, given our renderer context (see the documentation
    # for `#build_binding_context`) and renders the production-ready entry.
    #
    # @return [String] The rendered entry.
    def render
      ERB.new(File.read layout_file).result context
    end

    private

    attr_reader :context, :entry, :layout_file

    # @private
    # @param entry [Lifer::Entry] The entry to be rendered.
    # @return [void]
    def initialize(entry:)
      @entry = entry
      @layout_file = entry.collection.layout_file
      @context = build_binding_context
    end

    # @private
    # Each collection name is provided as a local variable. This allows you to
    # make ERB files that contain loops like:
    #
    #     <% my_collection_name.entries.each do |entry| %>
    #       <%= entry.title %>
    #     <% end %>
    #
    # You can also access a complete list of collections via `collections.all` or
    # an individual collection via `collections.my_collection_name`.
    #
    # So, he following variables are provided:
    #
    #   - Any collection by name.
    #   - `:collections`: Access collections on this variable via an `#all`
    #     array or via any collection name.
    #   - `:settings`: For all your (non-default) Lifer settings.
    #   - `:content`: The HTML version of the in-scope entry.
    #
    # The `:content` variable is especially powerful, as it also parses any
    # given entry that's an ERB file with the same local variables in context.
    #
    # @return [Binding] A binding object with preset context from the current
    #   Lifer project and in-scope entry.
    def build_binding_context
      binding.tap { |binding|
        Lifer.collections.each do |collection|
          binding.local_variable_set collection.name, collection

          collection_context_module.define_singleton_method(collection.name) do
            collection
          end
        end

        binding.local_variable_set :collections, collection_context_module
        binding.local_variable_set :settings, Lifer.settings
        binding.local_variable_set :content,
          ERB.new(entry.to_html).result(binding)
      }
    end

    # @private
    def collection_context_module
      @collection_context_module ||=
        Module.new do
          class << self
            def all = Lifer.collections
          end
        end
    end
  end
end
