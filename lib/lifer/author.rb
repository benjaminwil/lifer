module Lifer
  # An author is a representation of a unique author of entries in the current
  # project. This allows us to refer to an author's name in an entry's
  # frontmatter, i.e.:
  #
  #     ---
  #     title: My blog post
  #     author: Nat McCartney
  #     ---
  #
  # And let that reference load in a bunch of other metadata about the
  # author. While it's possible to add all of this metadata at the entry level,
  # the first entry loaded will be the source of truth for every reference
  # back to the author. So it's preferrable to set the author metadata in your
  # global configuration:
  #
  #    # my-lifer.conf
  #    authors:
  #      - name: Nat McCartney
  #        url: https://example.com/nat
  #        avatar: https://example.com/nat.png
  #
  # Within a Lifer project, this allows you to do powerful things like get
  # a list of entries by a unique author (or set of authors). It also allows
  # you to provide author-specific URLs and avatar images in your website's
  # JSON Feeds.
  #
  # The author's name is used as the primary identifier. We have tried to be
  # smart about this so that, for example, "Nat McCartney", "nat mccartney",
  # and "nat-mccartney" will all load up the same author object.
  #
  class Author
    class AmbiguousURIError < StandardError; end

    class << self
      # Builds or updated a Lifer author. On update, the list of an author's
      # entries would get freshened.
      #
      # @param name [String] The name of the author.
      # @param url [String] A relative or absolute URL to learn more about
      #   the author at.
      # @param avatar [String] A relative or absolute URL to an image that
      #   represents the author.
      def build_or_update(name:, url: nil, avatar: nil, entries: [])
        update(name:, url:, avatar:, entries:) ||
          build(name:, url:, avatar:, entries:)
      end

      private

      def build(name:, url:, avatar:, entries:)
        if (new_author = new(name:, url:, avatar:, entries:))
          Lifer.author_manifest << new_author
        end
        new_author || false
      end

      def update(name:, url:, avatar:, entries:)
        author_id = Lifer::Utilities.handleize(name)

        if (author = Lifer.authors.detect { _1.id == author_id })
          author.instance_variable_set :@entries,
            (author.instance_variable_get(:@entries) | entries)
        end
        author || false
      end
    end

    attr_reader :name, :entries

    def initialize(name:, url:, avatar:, entries:)
      @name = name
      @url = url
      @avatar = avatar
      @entries = entries
    end

    # An avatar image URL that represents the author. The URL can either be
    # relative from the website's root or an absolute URL. If the relative or
    # absolute URL is ambiguous, it is sanitized and this method returns nil.
    #
    # @param host [String] The host to prefix to relative URLs. By default,
    # this is the Lifer project's global host.
    # @return [String] The absolute URL to the avatar image.
    def avatar(host: Lifer.setting(:global, :host)) = uri_from(@avatar, host:)

    # An identifier built from the author's name. This uses our generic
    # handle-izer function. So a name like "Nat McCartney" becomes
    # "nat-mccartney".
    #
    # @return [String] The identifier for the author.
    def id = (@id ||= Lifer::Utilities.handleize(name))

    # A URL that provides more info about the author. The URL can either be
    # relative from the website's root or an absolute URL. If the relative or
    # absolute URL is ambiguous, it is sanitized and this method returns nil.
    #
    # @param host [String] The host to prefix to relative URLs. By default,
    # this is the Lifer project's global host.
    # @return [String] The absolute version of the URL.
    def url(host: Lifer.setting(:global, :host)) = uri_from(@url, host:)

    private

    def uri_from(string, host:)
      uri = string && URI.parse(string.strip)

      if uri && uri.relative? && uri.to_s.start_with?("/")
        "%s%s" % [host, uri]
      elsif uri && uri.relative? && !uri.to_s.start_with?("/")
        raise AmbiguousURIError
      elsif uri&.absolute?
        uri.to_s
      end
    rescue AmbiguousURIError
      Lifer::Message.error("author.ambiguous_uri_error", name:, uri: uri.to_s)
      nil
    end
  end
end
