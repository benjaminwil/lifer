# frozen_string_literal: true

module Lifer
  VERSION = "0.2.0"
end

Gem::Specification.new do |spec|
  spec.name          = "lifer"
  spec.version       = Lifer::VERSION
  spec.authors       = ["benjamin wil"]
  spec.email         = ["benjamin@super.gd"]

  spec.summary       = "Minimal static weblog generator."
  spec.description   = "Minimal static weblog generator. Good RSS feeds."
  spec.homepage      = "https://github.com/benjaminwil/lifer"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "%s/blob/main/CHANGELOG.md" % spec.homepage

  # Specify which files should be added to the gem when it is released. The
  # `git ls-files -z` loads the files in the RubyGem that have been added into
  # git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`
      .split("\x0")
      .reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "kramdown", "~> 2.4"

  spec.add_development_dependency "debug"
end
