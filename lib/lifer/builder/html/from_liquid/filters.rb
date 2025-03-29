# This module provides Liquid filters to be used within Liquid templates.
# In many cases these utilities exist to be pseudo-compatible with Jekyll.
#
# @example A filter in a Liquid template.
#     {{ entry.published_at | date_to_xmlschema }}
#
module Lifer::Builder::HTML::FromLiquid::Filters
  # @!visibility private
  Util = Lifer::Utilities

  # Converts date to ISO-8601 format.
  #
  # @param input [String] A date string, I hope.
  # @return [String] The transformed date string.
  def date_to_xmlschema(input) = Util.date_as_iso8601(input)

  # Transforms a string to kabab-case.
  #
  # @example Result
  #     handleize("hello_there") #=> "hello-there"
  #
  # @param input [String] A string.
  # @return [String] The transformed string.
  def handleize(input) = Util.handleize(input)
end
