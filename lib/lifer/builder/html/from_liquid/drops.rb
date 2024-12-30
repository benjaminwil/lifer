class Lifer::Builder::HTML::FromLiquid
  # This module contains all of custom Liquid data drops used in order to render
  # Lifer entries.
  #
  # For more information about drops, see the `liquid` gem source code. (The
  # docs are awful.)
  #
  module Drops; end
end

require_relative "drops/collection_drop"
require_relative "drops/collections_drop"
require_relative "drops/entry_drop"
require_relative "drops/frontmatter_drop"
require_relative "drops/settings_drop"
