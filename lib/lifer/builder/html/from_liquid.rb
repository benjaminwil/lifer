require "liquid"

require_relative "from_liquid/drops"
require_relative "from_liquid/filters"
require_relative "from_liquid/liquid_env"

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
      document = Liquid::Template
        .parse(layout_file_contents, **parse_options)
        .render(document_context, **render_options)

      return document unless (relative_layout_path = frontmatter[:layout])

      layout_path = "%s/%s" % [Lifer.root, relative_layout_path]
      document_context = context.merge! "content" => document
      Liquid::Template
        .parse(File.read layout_path, **parse_options)
        .render(document_context, **render_options)
    end

    private

    def initialize(entry:)
      @entry = entry
      @layout_file = entry.collection.layout_file
    end

    def context
      collections = Drops::CollectionsDrop.new
      tags = Drops::TagsDrop.new
      collection = collections
        .to_a
        .detect { _1.name.to_sym == entry.collection.name }
      entry_tags = tags.to_a.select { entry.tags.include? _1 }

      {
        "collections" => collections,
        "tags" => tags,
        "entry" => Drops::EntryDrop.new(entry, collection:, tags: entry_tags),
        "parse_options" => parse_options,
        "render_options" => render_options,
        "settings" => Drops::SettingsDrop.new
      }
    end

    def frontmatter
      return {} unless frontmatter?

      Lifer::Utilities.symbolize_keys(
        YAML.load layout_file_contents(raw: true)[Lifer::FRONTMATTER_REGEX, 1],
          permitted_classes: [Time]
      )
    end

    def frontmatter?
      @frontmatter ||=
        layout_file_contents(raw: true).match?(Lifer::FRONTMATTER_REGEX)
    end

    def layout_file_contents(raw: false)
      cache_variable = "@layout_file_contents_#{raw}"
      cached_value = instance_variable_get cache_variable

      return cached_value if cached_value

      contents =
        if raw
          File.read(layout_file)
        else
          File.read(layout_file).gsub(Lifer::FRONTMATTER_REGEX, "")
        end
      contents
      instance_variable_set cache_variable, contents
      contents
    end

    def liquid_environment = (@liquid_environment ||= LiquidEnv.global)

    def parse_options
      {
        environment: liquid_environment,
        error_mode: :strict
      }
    end

    def render_options
      {
        registers: {file_system: liquid_environment.file_system},
        strict_variables: true,
        strict_filters: true
      }
    end
  end
end
