# A selection is a group of entries that belong to any collection.
# Lifer includes some selection classes by default, but the intent here is to
# let users bring their own selections.
#
# A selection subclass can be added to the Lifer project as a Ruby file. Any
# detected Ruby files are dynamically loaded when `Lifer::Brain` is initialized.
#
# Implementing a selection is simple. Just implement the `#entries` method and
# rovide a name. The `#entries` method can be used to filter down
# `Lifer.entry_manifest` in whichever way one needs. To see examples of this,
# check out the source code of any of the included selections.
#
class Lifer::Selection < Lifer::Collection
  class << self
    attr_accessor :name

    # The constructor method for selections. Unlike collections:
    #
    #   1. Selections never have a unique instance name. (There is only one
    #      instance of each selection, and it's inherited from the class.)
    #   2. Selections never have a directory. Selections are virtual,
    #      pseudo-collections that paste together entries across collections.
    #
    # Thus, the generator method here takes no arguments.
    #
    # @return [Lifer::Selection]
    def generate
      new(name: name, directory: nil)
    end

    private

    # @private
    # This callback is invoked whenever a subclass of the current class is
    # created. It ensures that each subclass, at least, as a default name that
    # isn't `nil`.
    #
    # @return [void]
    def inherited(klass)
      klass.name ||= :unnamed_selection
    end
  end

  # The `#entries` method should be implemented on every selection subclass.
  #
  # @raise [NotImplementedError]
  def entries
    raise NotImplementedError, I18n.t("selection.entries_not_implemented")
  end

  # FIXME:
  # Getting selection settings may actually need to be different than getting
  # collection settings. But for now let's just inherit the superclass method.
  #
  # A getter for selection settings. See `Lifer::Collection#setting` for more
  # information.
  #
  # @return [String, Symbol, NilClass] The setting for the collection (or a
  #   fallback setting, or a default setting).
  def setting(...)
    super(...)
  end

  private

  # @private
  # Selections do not support layout files. Entries only have permalinks and
  # layouts via their collections. If something were ever to ask for the layout
  # file of a selection, it would be wrong to. So we would raise an error.
  #
  def layout_file
    raise I18n.t("selection.layouts_not_allowed")
  end

  self.name = :selection
end

require_relative "selection/all_markdown"
require_relative "selection/included_in_feeds"
