require "erb"

class Lifer::Layout
  DEFAULT = "%s/templates/layout.html.erb" %
    File.expand_path(File.dirname(__FILE__))

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
    @template = template.nil? ? DEFAULT : template
  end
end
