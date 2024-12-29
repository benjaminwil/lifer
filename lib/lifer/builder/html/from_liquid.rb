require "liquid"

require_relative "from_liquid/drops"
require_relative "from_liquid/filters"
require_relative "from_liquid/layout_tag"

Liquid::Template.register_filter(Lifer::Builder::HTML::FromLiquid::Filters)
Liquid::Template.register_tag(:layout, Lifer::Builder::HTML::FromLiquid::LayoutTag)

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
class Lifer::Builder::HTML
  class FromLiquid
    class << self
      def build(entry:) = new(entry:).render
    end

    attr_accessor :entry, :layout_file

    def initialize(entry:)
      @entry = entry
      @layout_file = entry.collection.layout_file
    end

    def render_options
      {
        strict_variables: true,
        strict_filters: true
      }
    end

    def render
      Liquid::Template.file_system =
        Liquid::LocalFileSystem.new(Lifer.root, "%s.html.liquid")

      document_context = context.merge!(
        "content" => Liquid::Template
          .parse(entry.to_html, error_mode: :strict)
          .render(context, render_options)
      )
      Liquid::Template
        .parse(layout, error_mode: :strict)
        .render(document_context, render_options)
    end

    private

    def context
      collections = Drops::CollectionsDrop.new
      collection = collections
        .to_a
        .detect { _1.name.to_sym == entry.collection.name }

      {
        "collections" => collections,
        "entry" => Drops::EntryDrop.new(entry, collection:),
        "settings" => Drops::SettingsDrop.new
      }
    end

    def layout
      contents = File.read layout_file

      return contents unless contents.match?(/\{%\s*#{LayoutTag::NAME}.*%\}/)

      contents + "\n{% #{LayoutTag::ENDNAME} %}"
    end
  end
end
