require "erb"

class Lifer::Builder::SimpleHTMLFromERB
  class Layout
    DEFAULT = "%s/lib/lifer/templates/layout.html.erb" % Lifer.gem_root

    class << self
      def build(entry:, template: DEFAULT)
        new(entry: entry, template: template).render { entry.to_html }
      end
    end

    def render
      ERB.new(File.readlines(template).join).result(binding)
    end

    private

    attr_reader :entry, :template

    def initialize(entry:, template:)
      @entry = entry
      @template = template_file template
    end

    def template_file(template)
      return DEFAULT if template.nil? || template == DEFAULT
      return template if template.include?(Lifer.root)

      [Lifer.root, template].join "/"
    end
  end
end
