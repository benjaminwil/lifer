require "date"
require "kramdown"
require "time"

require_relative "../utilities"

# We should initialize each Markdown file in a Lifer project as a
# `Lifer::Entry::Markdown` object. This class contains convenience methods for
# parsing a Markdown file with frontmatter as a weblog post or article. Of course,
# all frontmatter key-values will be available for users to render as they will in
# their template files.
#
# FIXME: As we add other types of entries, especially ones that use frontmatter,
# it may make sense to pull some of these methods into a separate module.
#
class Lifer::Entry::Markdown < Lifer::Entry
  # If a filename contains a date, we should expect it to be in the following
  # format.
  #
  FILENAME_DATE_FORMAT = /^(\d{4}-\d{1,2}-\d{1,2})-/

  # We expect frontmatter to be provided in the following format.
  #
  FRONTMATTER_REGEX = /^---\n(.*)---\n/m

  # We truncate anything that needs to be truncated (summaries, meta
  # descriptions) at the following character count.
  #
  TRUNCATION_THRESHOLD = 120

  self.include_in_feeds = true
  self.input_extensions = ["md"]
  self.output_extension = :html

  # Given the entry's frontmatter, we should be able to get a list of authors.
  # We always prefer authors (as opposed to a singular author) because it makes
  # handling both cases easier in the long run.
  #
  # The return value here is likely an author's name. Whether that's a full
  # name, a first name, or a handle is up to the end user.
  #
  # @return [Array<String>] An array of authors's names.
  def authors
    Array(frontmatter[:author] || frontmatter[:authors]).compact
  end

  # This method returns the full text of the entry, only removing the
  # frontmatter. It should not parse anything other than frontmatter.
  #
  # @return [String] The body of the entry.
  def body
    return full_text.strip unless frontmatter?

    full_text.gsub(FRONTMATTER_REGEX, "").strip
  end

  # Since Markdown files would only store dates as simple strings, it's nice to
  # attempt to convert those into Ruby date or datetime objects.
  #
  # @return [Time] A Ruby representation of the date and time provided by the
  #   entry frontmatter or filename.
  def date
    date_data = frontmatter[:date] || filename_date

    case date_data
    when Time then date_data
    when String then DateTime.parse(date_data).to_time
    else
      Lifer::Message.log("entry.markdown.no_date_metadata", filename: file)
      Lifer::Entry::DEFAULT_DATE
    end
  rescue ArgumentError => error
    Lifer::Message.error("entry.markdown.date_error", filename: file, error:)
    Lifer::Entry::DEFAULT_DATE
  end

  # Frontmatter is a widely supported YAML metadata block found at the top of
  # Markdown files. We should attempt to parse Markdown entries for it.
  #
  # @return [Hash] A hash representation of the entry frontmatter.
  def frontmatter
    return {} unless frontmatter?

    Lifer::Utilities.symbolize_keys(
      YAML.load(full_text[FRONTMATTER_REGEX, 1], permitted_classes: [Time])
    )
  end

  # FIXME:
  # This would be easier to test and more appropriate as a module method
  # takes text and options as arguments.
  #
  # If given a summary in the frontmatter of the entry, we can use this to
  # provide a summary. Otherwise, we can truncate the first paragraph and use
  # that as a summary, although that is a bit annoying. This is useful for
  # indexes and feeds and so on.
  #
  # @return [String] A summary of the entry.
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

  # The title or a default title.
  #
  # @return [String] The title of the entry.
  def title
    frontmatter[:title] || Lifer.setting(:entries, :default_title)
  end

  # The HTML representation of the Markdown entry as parsed by Kramdown.
  #
  # FIXME: Before converting a Kramdown document to Markdown, we chould
  #   convert any relative URLs to absolute ones. This makes it more flexible to
  #   use HTML output where ever we want, especially in RSS feeds where feed
  #   readers may "wtf" a relative URL.
  #
  # @return [String] The HTML for the body of the entry.
  def to_html
    Kramdown::Document.new(body).to_html
  end

  private

  # @private
  def filename_date
    return unless file && File.basename(file).match?(FILENAME_DATE_FORMAT)

    File.basename(file).match(FILENAME_DATE_FORMAT)[1]
  end

  # Using Kramdown we can detect the first paragraph of the entry.
  #
  # @private
  def first_paragraph
    @first_paragraph ||=
      kramdown_paragraph_text(
        Kramdown::Document.new(body).root
          .children
          .detect { |child| child.type == :p }
      )
  end

  # @private
  def frontmatter?
    full_text && full_text.match?(FRONTMATTER_REGEX)
  end

  # @private
  def kramdown_paragraph_text(kramdown_element)
    return if kramdown_element.nil?

    kramdown_element.children
      .flat_map { |child| child.value || kramdown_paragraph_text(child) }
      .join
      .gsub(/\n/, " ")
  end
end
