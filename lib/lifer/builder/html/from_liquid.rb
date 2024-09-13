require "liquid"

require_relative "from_liquid/drops"

# If the HTML builder is given a Liquid template, it uses this class to parse
# the Liquid into HTML. Lifer project metadata is provided as context. For
# example:
#
#     <html>
#       <head>
#         <title>{{ my_collection.name }}</title>
#       </head>
#
#       <body>
#         <h1>{{ my_collection.name }}</h1>
#
#         {% for entry in my_collection.entries %}
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

    def render
      document_context = context.merge!(
        "content" => Liquid::Template.parse(entry.to_html).render(context)
      )
      Liquid::Template.parse(File.read layout_file).render(document_context)
    end

    private

    def context
      {
        "collections" => CollectionsDrop.new,
        "settings" => SettingsDrop.new
      }
    end
  end
end
