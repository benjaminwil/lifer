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
  #         <%= partial "_layouts/header.html.erb" %>
  #
  #         <h1><%= my_collection.name %></h1>
  #
  #         <% my_collection.entries.each do |entry| %>
  #           <section>
  #             <h2><%= entry.title %></h2>
  #             <p><%= entry.summary %></p>
  #             <a href="<%= entry.permalink %>">Read more</a>
  #           </section>
  #         <% end %>
  #
  #         <%= partial "_layouts/footer.html.erb" %>
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

        define_singleton_method :render,
          -> (relative_path_to_template, locals = {}) {
            partial_render_method relative_path_to_template, locals
          }
      }
    end

    def collection_context_class
      @collection_context_class ||= Class.new(Array) do end
    end

    def tag_context_class
      @tag_context_class ||= Class.new(Array) do end
    end

    # @private
    # If the end user should want to render a partial from an entry or a layout
    # file, this method provides the functionality for the `#partial` method
    # provided to the ERB template context, complete with all of the information
    # one might want want about the entry, project collections, and so on, that's
    # available from entry and layout templates.
    #
    # @example Usage
    #    <%= partial "_layouts/my_partial.html.erb", id: "123" %>
    # @param relative_path_to_template [String] The path, from the Lifer root,
    #   to the partial layout file.
    # @param locals [Hash] Additional data that should be passed along for
    #   rendering the partial.
    # @return [String] The rendered partial document.
    def partial_render_method(relative_path_to_template, locals)
      template_path = File.join(Lifer.root, relative_path_to_template)

      partial_binding = binding.tap { |binding|
        context.local_variables.each do |variable|
          next if variable == :content

          binding.local_variable_set variable,
            context.local_variable_get(variable)
        end

        locals.each do |key, value|
          binding.local_variable_set key.to_sym, value
        end
      }

      ERB.new(File.read template_path).result(partial_binding)
    end
  end
end
