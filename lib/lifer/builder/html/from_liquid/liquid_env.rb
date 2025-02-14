class Lifer::Builder::HTML::FromLiquid
  # From the `liquid` gem's README:
  #
  # "In Liquid, a "Environment" is a scoped environment that encapsulates
  # custom tags, filters, and other configurations. This allows you to
  # define and isolate different sets of functionality for different
  # contexts, avoiding global overrides that can lead to conflicts
  # and unexpected behavior."
  #
  # For Lifer, we simply use a single global environment for each build.
  #
  class LiquidEnv
    # Returns the global Liquid environment that contains all local
    # templates, custom tags, and filters.
    #
    # @return [Lifer::Environment]
    def self.global
      Liquid::Environment.build do |environment|
        environment.error_mode = :strict

        environment.file_system =
          Liquid::LocalFileSystem.new(Lifer.root, "%s.html.liquid")

        environment.register_filter Lifer::Builder::HTML::FromLiquid::Filters
        environment.register_tag "layout",
          Lifer::Builder::HTML::FromLiquid::LayoutTag
      end
    end
  end
end
