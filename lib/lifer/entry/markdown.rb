require "date"
require "kramdown"
require "time"

require_relative "../utilities"

# We should initialize each Markdown file in a Lifer project as a
# `Lifer::Entry::Markdown` object. This class contains convenience methods for
# parsing a Markdown file with frontmatter as a weblog post or article. Of
# course, all frontmatter key-values will be available for users to render as
# they will in their template files.
#
# @fixme As we add other types of entries, especially ones that use frontmatter,
# it may make sense to pull some of these methods into a separate module.
#
class Lifer::Entry::Markdown < Lifer::Entry
  self.include_in_feeds = true
  self.input_extensions = ["md"]
  self.output_extension = :html

  # If given a summary in the frontmatter of the entry, we can use this to
  # provide a summary. Otherwise, we can truncate the first paragraph and use
  # that as a summary, although that is a bit annoying. This is useful for
  # indexes and feeds and so on.
  #
  # @fixme This would be easier to test and more appropriate as a module method
  #   takes text and options as arguments.
  #
  # @return [String] A summary of the entry.
  def summary
    return super if super

    return if raw_first_paragraph_text.nil?

    text = raw_first_paragraph_text
    return text if text.length <= TRUNCATION_THRESHOLD

    truncated_text = text[0..TRUNCATION_THRESHOLD]
    if (index_of_final_fullstop = text.rindex ". ")
      truncated_text[0..index_of_final_fullstop]
    else
      "%s..." % truncated_text
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
  # @fixme Before converting a Kramdown document to Markdown, we should convert
  #   any relative URLs to absolute ones. This makes it more flexible to use
  #   HTML output where ever we want, especially in RSS feeds where feed
  #   readers may "wtf" a relative URL.
  #
  # @return [String] The HTML for the body of the entry.
  def to_html
    @to_html ||= Kramdown::Document.new(body).to_html
  end

  private

  # It is conventional for users to use spaces or commas to delimit tags in
  # other systems, so let's support that. But let's also support YAML-style
  # arrays.
  #
  # @return [Array<String>] An array of candidate tag names.
  def candidate_tag_names
    case frontmatter[:tags]
    when Array then frontmatter[:tags].map(&:to_s)
    when String then frontmatter[:tags].split(TAG_DELIMITER_REGEX)
    else []
    end.uniq
  end

  # Detects the raw paragraph text from the entry.
  #
  # @fixme It would be easier and less error prone to do this with Nokogiri. But
  #   we currently don't need the dependency for any other reason, so let's
  #   defer adding it until then.
  # @private
  def raw_first_paragraph_text
    paragraphs = to_html.match %r{<p[^>]*>(.*?)</p>}im
    paragraph = paragraphs ? paragraphs[1].strip : nil

    return unless paragraph

    paragraph = paragraph.gsub /<\/?[^>]*>/, ""
    paragraph = CGI.unescapeHTML paragraph
    paragraph.gsub(/[\s\n\t]+/, " ").strip
  end
end
