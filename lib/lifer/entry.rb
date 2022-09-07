require "date"
require "kramdown"
require "time"

require_relative "utilities"

class Lifer::Entry
  FILENAME_DATE_FORMAT = /^(\d{4}-\d{1,2}-\d{1,2})-/
  FRONTMATTER_REGEX = /^---\n(.*)---\n/m

  attr_reader :file

  def initialize(file:)
    @file = File.exist?(file) ? Pathname(file) : nil
  end

  def body
    return full_text.strip unless frontmatter?

    full_text.gsub(FRONTMATTER_REGEX, "").strip
  end

  def date
    date_data = frontmatter[:date] || filename_date

    case date_data
    when Time then date_data
    when String then DateTime.parse(date_data).to_time
    else
      puts "[%s]: no date metadata" % [file]
      nil
    end
  rescue ArgumentError => error
    puts "[%s]: %s" % [file, error]
    nil
  end

  def frontmatter
    return {} unless frontmatter?

    Lifer::Utilities.symbolize_keys(
      YAML.load(full_text[FRONTMATTER_REGEX, 1], permitted_classes: [Time])
    )
  end

  def full_text
    File.readlines(file).join if file
  end

  def to_html
    Kramdown::Document.new(body).to_html
  end

  private

  def filename_date
    return unless file && File.basename(file).match?(FILENAME_DATE_FORMAT)

    File.basename(file).match(FILENAME_DATE_FORMAT)[1]
  end

  def frontmatter?
    full_text && full_text.match?(FRONTMATTER_REGEX)
  end
end
