module Lifer
  # A tag is a way to categorize entries. You've likely encountered tags in
  # other software before. In Lifer, tags are sort of the inverse of
  # collections. It's a nice way to associate entries across many collections.
  #
  # Because tags are used to link entries, we definitely do not want duplicate
  # tags. So the only way to build or retrieve tags is via the
  # `.build_or_update` class method, which helps us responsibly manage the
  # global tag manifest.
  #
  class Tag
    class << self
      # Builds or updates a Lifer tag. On update, its list of entries gets
      # freshened.
      #
      # @param name [String] The name of the tag.
      # @param entries [Array<Lifer::Entry>] A list of entries that should be
      #   associated with the tag. This parameter is not a true writer, in that
      #   if the tag already exists, old entry associations won't be removed--
      #   only appended to.
      # @return [Lifer:Tag] The new or updated tag.
      def build_or_update(name:, entries: [])
        update(name:, entries:) || build(name:, entries:)
      end

      private

      def build(name:, entries:)
        if (new_tag = new(name:, entries:))
          Lifer.tag_manifest << new_tag
        end
        new_tag || false
      end

      def update(name:, entries:)
        if (tag = Lifer.tags.detect { _1.name == name })
          tag.instance_variable_set :@entries,
            (tag.instance_variable_get(:@entries) | entries)
        end
        tag || false
      end
    end

    attr_accessor :name

    attr_reader :entries

    def initialize(name:, entries:)
      @name = name
      @entries = entries
    end
  end
end
