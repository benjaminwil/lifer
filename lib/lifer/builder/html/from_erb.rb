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
  class FromERB < FromAny
    # Reads the entry as ERB, given our renderer context (see the documentation
    # for `#build_binding_context`) and builds the production-ready entry.
    #
    # @return [String] The resulting HTML entry.
    def build
      document = ERB.new(layout_file_contents).result context

      return document unless (relative_layout_path = frontmatter[:layout])

      document_binding = binding.tap { |binding|
        context.local_variables.each do |variable|
          next if variable == :content

          binding.local_variable_set variable,
            context.local_variable_get(variable)
        end
        binding.local_variable_set :content, document
      }

      layout_path = "%s/%s" % [Lifer.root, relative_layout_path]
      ERB.new(File.read layout_path).result(document_binding)
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

        collections = collection_context_class.new Lifer.collections
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
