class Lifer::Builder::HTML::FromLiquid
  class LayoutTag < Liquid::Block
    NAME = :layout
    ENDNAME = ("end%s" % NAME).to_sym

    def initialize(layout, path, options)
      path = path.delete("\"").strip
      super
      @layout = Liquid::Template.file_system.read_template_file(path)
    end

    def render(context)
      document_context = context.environments.first

      current_layout_file = File
        .read(document_context["entry"]["collection"]["layout_file"])
        .gsub(/\{%\s*#{tag_name}.+%\}/, "")

      content_with_layout = Liquid::Template
        .parse(current_layout_file, error_mode: :strict)
        .render(document_context, render_options)

      Liquid::Template
        .parse(@layout, error_mode: :strict)
        .render(
          document_context.merge({"content" => content_with_layout}),
          render_options
        )
    end

    def render_options = {strict_variables: true, strict_filters: true}
  end
end
