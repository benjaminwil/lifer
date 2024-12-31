require "liquid"

require_relative "from_liquid/drops"
require_relative "from_liquid/filters"
require_relative "from_liquid/layout_tag"

class Lifer::Builder::HTML
  # If the HTML builder is given a Liquid template, it uses this class to parse
  # the Liquid into HTML. Lifer project metadata is provided as context. For
  # example:
  #
  #     <html>
  #       <head>
  #         <title>{{ collections.my_collection.name }}</title>
  #       </head>
  #
  #       <body>
  #         <h1>{{ collections.my_collection.name }}</h1>
  #
  #         {% for entry in collections.my_collection.entries %}
  #           <section>
  #             <h2>{{ entry.title }}</h2>
  #             <p>{{ entry.summary }}</p>
  #             <a href="{{ entry.permalink }}">Read more</a>
  #           </section>
  #         {% endfor %}
  #       </body>
  #     </html>
  #
  class FromLiquid
    class << self
      # Render and build a Lifer entry.
      #
      # @param entry [Lifer::Entry] The entry to render.
      # @return [String] The rendered entry, ready for output.
      def build(entry:) = new(entry:).render
    end

    attr_accessor :entry, :layout_file

    # Reads the entry as Liquid, given our document context, and renders
    # an entry.
    #
    # @return [String] The rendered entry.
    def render
      document_context = context.merge!(
        "content" => Liquid::Template
          .parse(entry.to_html, **parse_options)
          .render(context, **render_options)
      )
      Liquid::Template
        .parse(layout, **parse_options)
        .render(document_context, **render_options)
    end

    private

    def initialize(entry:)
      @entry = entry
      @layout_file = entry.collection.layout_file
    end

    def context
      collections = Drops::CollectionsDrop.new
      collection = collections
        .to_a
        .detect { _1.name.to_sym == entry.collection.name }

      {
        "collections" => collections,
        "entry" => Drops::EntryDrop.new(entry, collection:),
        "parse_options" => parse_options,
        "render_options" => render_options,
        "settings" => Drops::SettingsDrop.new
      }
    end

    # @private
    # It's possible for the provided layout to request a parent layout, which
    # makes this method a bit complicated.
    #
    # @return [String] A Liquid layout document, ready for parsing.
    def layout
      contents = File.read layout_file

      return contents unless contents.match?(/\{%\s*#{LayoutTag::NAME}.*%\}/)

      contents + "\n{% #{LayoutTag::ENDNAME} %}"
    end

    def liquid_environment
      @liquid_environment ||= Liquid::Environment.build do |environment|
        environment.file_system =
          Liquid::LocalFileSystem.new(Lifer.root, "%s.html.liquid")

        environment.register_filter Lifer::Builder::HTML::FromLiquid::Filters
        environment.register_tag "layout",
          Lifer::Builder::HTML::FromLiquid::LayoutTag
      end
    end

    def parse_options
      {
        environment: liquid_environment,
        error_mode: :strict
      }
    end

    def render_options
      {
        strict_variables: true,
        strict_filters: true
      }
    end
  end
end
