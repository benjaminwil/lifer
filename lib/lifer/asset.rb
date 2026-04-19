class Lifer::Asset
  # An asset is a file, often a multimedia file, that belongs to one or
  # many entries. Right now, assets don't have much functionality of their
  # own, but it's valuable to know what entries an asset has a relationship
  # with. In the future, it may be valuable for us to build out functionality
  # that allows users to have one or more asset hosts. This allows files that
  # aren't checked into version control still be treated as entry dependencies.
  #
  class << self
    # Builds or updates a Lifer asset. On update, this list of an asset's
    # entries would get freshened.
    #
    # @param url [String] An absolute URL or path relative to the host root.
    # @param entries [Array<Lifer::Entry>] An array of entries that the asset
    #   belongs to.
    # @return [Lifer::Asset] The new or updated asset.
    def build_or_update(url: nil, entries: [])
      update(url:, entries:) || build(url:, entries:)
    end

    # The default host for all assets.
    #
    # @return [String] A URL to a host. (Default: the configured global host.)
    def default_host = Lifer.setting(:global, :host)

    private

    def build(url:, entries:)
      if (new_asset = new(url:, entries:))
        Lifer.asset_manifest << new_asset
      end
      new_asset || false
    end

    def update(url:, entries:)
      normalized_url = Lifer::Utilities.uri_from url,
        host: default_host,
        object_type: self

      if (asset = Lifer.asset_manifest.detect { _1.url == normalized_url })
        asset.instance_variable_set :@entries,
          (asset.instance_variable_get(:@entries) | entries)
      end
      asset || false
    end

  end

  attr_reader :url, :entries

  def initialize(url:, entries:)
    normalized_url = Lifer::Utilities.uri_from url,
      host: self.class.default_host,
      object_type: self

    @url = normalized_url
    @entries = entries
  end

  # Checks whether a given URL matches the current asset's URL.
  #
  # @param url [String] A URL.
  # @param host [String] The host URL. (Default: The configured global host
  #   URL.)
  # @return [boolean] Whether the given URL matches the object's URL.
  def match?(url:, host: self.class.default_host)
    @url == Lifer::Utilities.uri_from(url, host:, object_type: self.class)
  end

  # Gets the current URL. If given a host, the asset's true host will be
  # replaced with the given host.
  #
  # @param host [String] A host URL. (Default: The configured global host URL.)
  # @return [String] The URL to the current asset.
  def url(host: self.class.default_host)
    return @url if host == self.class.default_host

    path = URI(@url).path

    Lifer::Utilities.uri_from(path, host:, object_type: self.class)
  end
end
