require "kramdown"

require_relative "utilities"

class Lifer::Entry
  FRONTMATTER_REGEX = /^---\n(.*)---\n/m

  attr_reader :file

  def initialize(file:)
    @file = File.exist?(file) ? Pathname(file) : nil
  end

  def body
    return full_text.strip unless frontmatter?

    full_text.gsub(FRONTMATTER_REGEX, "").strip
  end

  def frontmatter
    return nil unless frontmatter?

    Lifer::Utilities.symbolize_keys(
      YAML.load full_text[FRONTMATTER_REGEX, 1]
    )
  end

  def full_text
    return unless file

    File.readlines(file).join
  end

  def to_html
    Kramdown::Document.new(body).to_html
  end

  private

  def frontmatter?
    full_text.match? FRONTMATTER_REGEX
  end
end
