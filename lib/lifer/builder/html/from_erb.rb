require "erb"

class Lifer::Builder::HTML
  # If the HTML builder is given an ERB template, it uses this class to parse
  # the ERB into HTML. Lifer project metadata is provided as context. For
  # example:
  #
  #     <html>
  #       <head>
  #         <title><%= my_collection.name %></title>
  #       </head>
  #
  #       <body>
  #         <h1><%= my_collection.name %></h1>
  #
  #         <% my_collection.entries.each do |entry| %>
  #           <section>
  #             <h2><%= entry.title %></h2>
  #             <p><%= entry.summary %></p>
  #             <a href="<%= entry.permalink %>">Read more</a>
  #           </section>
  #         <% end %>
  #       </body>
  #     </html>
  #
  class FromERB
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
    # Each collection and tag name is provided as a local variable. This allows
    # you to make ERB files that contain loops like:
    #
    #     <% collections.my_collection_name.entries.each do |entry| %>
    #       <%= entry.title %>
    #     <% end %>
    #
    # or:
    #
    #     <% tags.my_tag_name.entries.each do |entry| %>
    #       <%= entry.title %>
    #     <% end %>
    #
    # @return [Binding] A binding object with preset context from the current
    #   Lifer project and in-scope entry.
    def build_binding_context
      binding.tap { |binding|
        Lifer.collections.each do |collection|
          binding.local_variable_set collection.name, collection

          collection_context_class.define_method(collection.name) do
            collection
          end
        end

        Lifer.tags.each do |tag|
          binding.local_variable_set tag.name, tag

          tag_context_class.define_method(tag.name) do
            tag
          end
        end

        collections = collection_context_class.new Lifer.collections.to_a
        tags = tag_context_class.new Lifer.tags

        binding.local_variable_set :collections, collections
        binding.local_variable_set :settings, Lifer.settings
        binding.local_variable_set :tags, tags
        binding.local_variable_set :content,
          ERB.new(entry.to_html).result(binding)
      }
    end

    def collection_context_class
      @collection_context_class ||= Class.new(Array) do end
    end

    def tag_context_class
      @tag_context_class ||= Class.new(Array) do end
    end
  end
end
