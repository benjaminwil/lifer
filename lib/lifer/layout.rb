require "erb"

class Lifer::Layout
  DEFAULT = "%s/templates/layout.html.erb" %
    File.expand_path(File.dirname(__FILE__))

  class << self
    def build(entry:, template: DEFAULT)
      new(entry: entry, template: template)
        .render_minified { entry.to_html }
    end
  end

  def render_minified
    ERB.new(File.readlines(template).join).result(binding).tap { |result|
      result.gsub!(/>\s*[\n\t]+\s*</mi, '><')
      result.gsub!(/>\s*$/mi, '>')
      result.gsub!(/^\s*</mi, '<')
    }
  end

  private

  attr_reader :entry, :template

  def initialize(entry:, template:)
    @entry = entry
    @template = template
  end
end
