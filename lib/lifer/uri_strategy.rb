# A URI strategy is used by collections and builders to determine the output
# path of each entry. Depending on the strategy used, the output URI can be
# very different. For example, given:
#
#     Input file: 2020-01-01-my-trip-to-greece.md
#
# The output could be many things depending on the configured URI strategy:
#
#     Output file: https://example.com/my-trip-to-greece.html
#     Output file: https://example.com/2020/my-trip-to-greece/index.html
#     Output file: https://example.com/my-trip-to-greece-foo-bar-foo.html
#
# URI strategies are configured per collection.
#
class Lifer::URIStrategy
  include Lifer::Shared::FinderMethods

  class << self
    attr_accessor :name
  end

  attr_reader :root

  def initialize(root:)
    @root = root
  end

  # This method should always return the path to the file in the format
  # specified by the current URI strategy. For example, if the URI strategy was
  # to indexify every entry (the "pretty" strategy), input to output would look
  # like:
  #
  #     entry-name.md ---> entry-name/index.html
  #
  # @raise [NotImplementedError] This method must be implemented on each
  #   subclass.
  # @return [String] The path to the built output file.
  def output_file(entry)
    raise NotImplementedError, I18n.t("shared.not_implemented_method")
  end

  # This method should sometimes return the path to the file in the format
  # specified by the current URI strategy. Of course, this depends on what the URI
  # stategy is. For "pretty" strategies, the permalink may differ from the output
  # filename. For example, the output file may point to
  #
  #    entry-name/index.html
  #
  # While the permalink like points to:
  #
  #    entry-name
  #
  # @raise [NotImplementedError] This method must be implemented on each
  #   subclass.
  # @return [String] The permalink to the built output file.
  def permalink(entry)
    raise NotImplementedError, I18n.t("shared.not_implemented_error")
  end

  private

  def file_extension(entry) = entry.class.output_extension

  self.name = :uri_strategy
end

require_relative "uri_strategy/pretty"
require_relative "uri_strategy/pretty_root"
require_relative "uri_strategy/pretty_yyyy_mm_dd"
require_relative "uri_strategy/root"
require_relative "uri_strategy/simple"
