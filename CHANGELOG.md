## Next

## v0.10.2

This release resolves another bug in `Entry#summary` causing entries without
full-stops within the truncation threshold to not be truncated with a "..."
properly.

## v0.10.1

This release resolves a bug with `Entry#summary`. When I originally implemented
summaries as first paragraphs, I didn't realize that using the Kramdown
representation of the document would result in special characters being
transformed badly:

    In the ldquorealmrdquo where dreams dance

This change ensures that we don't end up with trash like that, or other HTML
trash.

The summary is meant to be ideal for things like `<meta>` description tags,
which should only contain plain text.


## v0.10.0

This release lets all layout files (either Liquid or ERB files) provide a
reference to parent, or "root", layout files that should wrap the via
frontmatter.

Previously, we did this for Liquid layouts using the custom `layout` tag. But
because there was no equivalent tag for ERB files, I realized it would be less
work to just provide the value via frontmatter. The same way for every type of
layout file.

End users (just me?) must update their Lifer project Liquid layouts accordingly:

```diff
- {% layout "layouts/root_layout.html.liquid" %}
+ ---
+ layout: layouts/root_layout.html.liquid
+ ---

  Layout content.
```

## v0.9.0

Atom feeds now support entries with both `#published_at` and `#updated_at`
timestamp. There is no standard equivalent way to provide this functonality for
RSS-format feeds, unfortunately. As part of this change, we removed all
`Entry#date` methods in favour of `Entry#published_at` onces. In Atom feeds, if
an article has no last updated date, the publication date is used instead.

Additionally, this release includes a new environment variable:
`LIFER_UNPARALLELIZED`. You can use this environment variable to run `lifer
build` or `lifer serve` without any parallelization turned on. This could be
useful for reproducing bugs and so on. Example usage:

    LIFER_UNPARALLELIZED=1 lifer build

## v0.8.0

### Tags

Entries now support tag frontmatter. This introduces a new way of making
associations between entries. Tags can encoded in entries as YAML arrays or as a
string (with comma and/or space delimiters):

    ---
    title: My Entry
    tags: beautifulTag, lovelyTag
    ---

    Blah blah blah.

Then, in your ERB or Liquid templates you can get entries via tag:

    <% tags.beautifulTag.entries.each do |entry| %>
      <li><%= entry.title %></li>
    <% end %>

### Frontmatter support across all entry types

Before this release, frontmatter was only supported by Markdown files. This
started to be annoying, because of features I wanted like tags. I figured it
couldn't hurt to just check any entry file for frontmatter, so that's how it
works now.

## v0.7.0

This release adds Atom feed support to the RSS builder. In your configuration
file, you can configure feed formats to `rss` (the default) or `atom` now:

    my_collection:
      rss:
        format: atom
        url: haha.xml

## v0.6.1

This release just fixes a mistake I made, where I built and pushed a tag from a
non-`main` branch, causing the RubyGems release to technically be for the wrong
SHA.

## v0.6.0

This release contains improvements to RSS feed generation:

- Additonal settings per RSS feed (maximum feed item count and configurable
  managing editor metadata).
- No more invalid `<managingEditor>` values. A default managing editor email is
  now prefixed to the default collection author name for [W3C validated
  feeds][w3c-feed-checker].

[w3c-feed-checker]: https://validator.w3.org/feed/check.cgi

## v0.5.1

Resolved warnings output by `gem build`.

## v0.5.0

This release refactors all of our builders to use parallelization, meaning that
`lifer build` process should be faster. It should be much faster for larger
projects. I'm using the `parallel` gem for parallelization at this time.

## v0.4.1

Resolves a bug where Liquid templates using the `{% layout %}` tag were not able
to render partials.

## v0.4.0

This release locks the `liquid` dependency to Liquid 5.6 or greater. Liquid 5.6
added `Liquid::Environment` for managing document context that was previously
stored in `Liquid::Template`, which was global and unsafe. This release ensures
that Lifer supports the new `Liquid::Environment` way of handling Liquid's local
filesystem for templates and partials.

## v0.3.0

This version marks the first version of Lifer that is kind of usable. The README
currently describes the big picture best. But I can add that, as of this version,
I've documented all of the public interfaces and added a good number of `FIXME`
comments to indicate functionality that _works_ but isn't quite where I want it
to be long term.

To manually test everything, I took my legacy Jekyll-based static site and
successfully ported it to Lifer.

The biggest thorn in my side is the Liquid rendering implementation. It works,
but the amount of trouble it was, and the not-very-serious way Liquid reports
rendering issues after build time, makes me think that this will come back to
haunt me.

Special thanks to [Chris][1] for helping me with some loading issues and
[Madeline][2] for helping me diagnose some disgusting Liquid template rendering
issues.

[1]: https://github.com/forkata
[2]: https://github.com/madelinecollier

## v0.2.0

![It's a living](lib/lifer/templates/its-a-living.png)
