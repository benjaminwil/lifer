# This module provides Liquid filters to be used within Liquid templates.
# In many cases these utilities exist to be pseudo-compatible with Jekyll.
#
# For example, a filter (in a Liquid template):
#
#     {{ entry.date | date_to_xmlschema }}
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
  # For example:
  #
  #     Before: hello_there
  #     After: hello-there
  # @param input [String] A string.
  # @return [String] The transformed string.
  def handleize(input) = Util.handleize(input)
end
