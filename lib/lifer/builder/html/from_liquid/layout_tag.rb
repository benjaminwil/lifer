class Lifer::Builder::HTML::FromLiquid
  # Note that if you want to learn more about the shape of this class, check out
  # `Liquid::Block` in the `liquid` gem.
  #
  # The layout tag is a bit magic. The idea here is to emulate how Jekyll
  # handles `layout:` YAML frontmatter within entries to change the normal
  # parent layout to an override parent layout--but without the need for
  # frontmatter.
  #
  # The reason we took this strategy was to avoid pre-processing every entry for
  # frontmatter when we didn't need to. Maybe in the long run this was a bad
  # call? I don't know.
  #
  # Example usage (from a Liquid template):
  #
  #     {% layout "path/to/my_liquid_layout_template" %}
  #
  # (The required `endlayout` tag will be appended to the end of the file
  # on render if you do not insert it yourself.
  #
  class LayoutTag < Liquid::Block
    # The name of the tag in Liquid templates, `layout`.
    #
    NAME = :layout

    # The end name of the tag in Liquid templates, `endlayout`.
    #
    ENDNAME = ("end%s" % NAME).to_sym

    def initialize(layout, path, options)
      @path = path.delete("\"").strip
      super
    end

    # A layout tag wraps an entire document and outputs it inside of whatever
    # the `@layout` is. This lets a child document specify a parernt layout!
    # Very confusing stuff.
    #
    # @param context [Liquid::Context] All of the context of the Liquid
    #   document that would be rendered.
    # @return [String] A rendered document.
    def render(context)
      document_context = context.environments.first
      parse_options = document_context["parse_options"]
      liquid_file_system = parse_options[:environment].file_system
      render_options = document_context["render_options"]

      current_layout_file = File
        .read(document_context["entry"]["collection"]["layout_file"])
        .gsub(/\{%\s*#{tag_name}.+%\}/, "")

      content_with_layout = Liquid::Template
        .parse(current_layout_file, error_mode: :strict)
        .render(document_context, render_options)

      Liquid::Template
        .parse(
          liquid_file_system.read_template_file(@path),
          **parse_options
        )
        .render(
          document_context.merge({"content" => content_with_layout}),
          **render_options
        )
    end
  end
end
