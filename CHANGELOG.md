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
