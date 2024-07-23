# Lifer

Lifer is an extensible static site generator. Out of the box, it provides a
classic static site generation experience, complete with RSS feed and ERB
templating. Unlike other Ruby-based static site generators, Lifer encourages you
to bring your own asset pipeline and configure it as a pre-build step.

_Lifer is currently in pre-release. Features are incomplete. Your mileage may
vary._

## Features

Here's a short overview of Lifer's flagship features.

### Bring your own asset pipeline

Whether you want to compile assets with Ruby-based tools, JavaScript-based
tools, or other tools, Lifer is okay with that. As long as those tools come with
a commandline interface, Lifer can shell out to those tools as a prebuild step.

### Collections and selections

If you have multiple collections of entries that must be output in different
ways, Lifer can help you do this. While every entry can only belong to a single
collection, you can create your own "selections" filter to group entries across
collections.

### Extensibility

Lifer autoloads any Ruby files included in the root of your project
automatically. This lets you specify your own custom output builders, feed
formats, and meta-collections of entries.

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

## Contributing

_TODO_
