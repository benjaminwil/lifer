require "date"
require "kramdown"
require "time"

require_relative "utilities"

class Lifer::Entry
  FILENAME_DATE_FORMAT = /^(\d{4}-\d{1,2}-\d{1,2})-/
  FRONTMATTER_REGEX = /^---\n(.*)---\n/m
  TRUNCATION_THRESHOLD = 120

  attr_reader :file, :collection

  def initialize(file:, collection:)
    if File.exist? file
      @file = Pathname file
      @collection = collection
    else
      raise StandardError, "file \"%s\" does not exist" % file
    end
  end

  def authors
    Array(frontmatter[:author] || frontmatter[:authors]).compact
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

  def permalink
    File.join Lifer.setting(:host),
      Lifer::URIStrategy
        .find_by_name(collection.setting :uri_strategy)
        .new(root: Lifer.root)
        .output_file(self)
  end

  # FIXME:
  # This would be easier to test and more appropriate as a module method
  # takes text and options as arguments.
  #
  def summary
    return frontmatter[:summary] if frontmatter[:summary]

    return if first_paragraph.nil?
    return first_paragraph if first_paragraph.length <= TRUNCATION_THRESHOLD

    truncated_paragraph = first_paragraph[0..TRUNCATION_THRESHOLD]
    if (index_of_final_fullstop = truncated_paragraph.rindex ". ")
      truncated_paragraph[0..index_of_final_fullstop]
    else
      "%s..." % truncated_paragraph
    end
  end

  def title
    frontmatter[:title] || Lifer.setting(:default_entry_title)
  end

  def to_html
    Kramdown::Document.new(body).to_html
  end

  private

  def filename_date
    return unless file && File.basename(file).match?(FILENAME_DATE_FORMAT)

    File.basename(file).match(FILENAME_DATE_FORMAT)[1]
  end

  def first_paragraph
    @first_paragraph ||=
      kramdown_paragraph_text(
        Kramdown::Document.new(body).root
          .children
          .detect { |child| child.type == :p }
      )
  end

  def frontmatter?
    full_text && full_text.match?(FRONTMATTER_REGEX)
  end

  def kramdown_paragraph_text(kramdown_element)
    return if kramdown_element.nil?

    kramdown_element.children
      .flat_map { |child| child.value || kramdown_paragraph_text(child) }
      .join
      .gsub(/\n/, " ")
  end
end
