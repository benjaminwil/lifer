# Lifer

Lifer is an extensible static site generator. Out of the box, it provides a
classic static site generation experience, complete with RSS feeds, ERB template
rendering, and Liquid template rendering. Unlike other Ruby-based static site
generators, Lifer encourages you to bring your own asset pipeline and configure
it as a pre-build step.

_Lifer is currently in pre-release. Features are incomplete. Your mileage may
vary._

**What's with the name?** Lifer aims to be easy to maintain for the lifetime of
your static site by requiring few dependencies and being very extensible by the
end user. There is no need for plugins in the form of separate Ruby gems. The
generator should also "breathe life" into your project because it's so easy to
use (🤞).

## Features

Here's a short overview of Lifer's flagship features.

### Bring your own asset pipeline

Whether you want to compile assets with Ruby-based tools, JavaScript-based
tools, or other tools, Lifer is okay with that. As long as those tools come with
a commandline interface, Lifer can shell out to those tools as a prebuild step.

The tradeoff here is that your templates will not be asset aware, meaning asset
fingerprinting and complex asset locating isn't really possible at this time. If
you need features like that, consider other static site generators or consider
*not* using a static site generator.

### Collections and selections

If you have multiple collections of entries that must be output in different
ways, Lifer can help you do this. While every entry can only belong to a single
collection, you can create your own "selections" filter to group entries across
collections.

### Extensibility

Lifer autoloads any Ruby files included in the root of your project
automatically. This lets you specify your own custom output builders, feed
formats, and meta-collections of entries.

### Development server

Need to preview your static site before your build it on your production server?
No problem. Just use the Lifer commandline interface to start a development
server at `http://localhost:9292`:

    $ lifer serve

The development server is not very sophisticated and can still be improved. But
for previewing new entries? It works just fine.

## Installation

_This installation guide assumes you already have Ruby 3 installed on your
system._

I recommend installing Lifer via Bundler. In the root directory of your static
site source, add a Gemfile if one doesn't exist already:

    $ bundle init

In the Gemfile, add the `lifer` gem:

```ruby
gem "lifer", "<= 1"
```

And then execute:

    $ bundle install

## Development

_This development guide assumes you already have Ruby 3 installed on your
system._

Clone this repository, install dependencies via Bundler, and ensure the test
suite can run on your machine:

    $ git clone https://github.com/benjaminwil/lifer lifer
    $ cd lifer
    $ bundle install
    $ bundle exec rspec

### Releases

We use the Bump gem to manage releases. Before releasing a version of Lifer:

1. Ensure unreleased changes have entries in the CHANGELOG file.
2. Ensure all tests pass locally.

Then use Bump to perform release chores and create a version tag:

    $ bundle exec bump <minor|patch> --tag --changelog --edit-changelog
    $ git push origin <new_version>

(Where `new_version` is the version you intend to release. For example:
`v1.2.3`.)

Then, build and push the gem to RubyGems:

    $ gem build
    $ gem push lifer-<new_version_without_the_v_prefix>.gem

And ensure that the release commit(s) are on the `main` branch:

    $ git push origin main

## Contributing

I'm not currently accepting unsolicited contributions to Lifer. I'm still
figuring out what the shape of this project is.

If you encounter bugs, please open an issue.

If you have ideas for improving existing functionality or adding *missing*
functionality, please open an issue. Maybe there is room for you to contribute,
but I don't want you to waste your time preparing a merge request that I won't
accept.
