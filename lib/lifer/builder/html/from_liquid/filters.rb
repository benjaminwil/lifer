module LiferLiquidFilters
  Util = Lifer::Utilities

  def date_to_xmlschema(input) = Util.date_as_iso8601(input)
  def handleize(input) = Util.handleize(input)
end
