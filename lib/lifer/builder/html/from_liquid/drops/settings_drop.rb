# This drop allows users to access the current Lifer project settings from
# Liquid templates. Example:
#
#     {{ settings.my_collection.uri_strategy }}
#
class SettingsDrop < Liquid::Drop
  def initialize(settings = Lifer.settings)
    @settings = Lifer::Utilities.stringify_keys(settings)
  end

  def as_drop(hash) = self.class.new(hash)

  def to_s = settings.to_json

  # Dynamically define Liquid accessors based on the Lifer settings object.
  # For example, to get a collections URI strategy:
  #
  #    {{ settings.my_collection.uri_strategy }}
  #
  # @param arg [String] The name of a collection.
  # @return [CollectionDrop, NilClass]
  def liquid_method_missing(arg)
    value = settings[arg]

    if value.is_a?(Hash)
      as_drop(value)
    elsif value.is_a?(Array) && value.all? { _1.is_a?(Hash) }
      value.map { as_drop(_1) }
    else
      value
    end
  end

  private

  attr_accessor :settings
end
