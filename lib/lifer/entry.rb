require "kramdown"

class Lifer::Entry
  attr_reader :file

  def initialize(file:)
    @file = File.exist?(file) ? Pathname(file) : nil
  end

  def text
    return unless file

    File.readlines(file).join
  end

  def to_html
    Kramdown::Document.new(text).to_html
  end
end
