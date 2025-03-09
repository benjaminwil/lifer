# frozen_string_literal: true

require_relative "lib/lifer/version"

Gem::Specification.new do |spec|
  spec.name          = "lifer"
  spec.version       = Lifer::VERSION
  spec.authors       = ["benjamin wil"]
  spec.email         = ["benjamin@super.gd"]
  spec.licenses      = ["MIT"]

  spec.summary       = "Minimal static weblog generator."
  spec.description   = "Minimal static weblog generator. Good RSS feeds."
  spec.homepage      = "https://github.com/benjaminwil/lifer"
  spec.required_ruby_version = ">= 3.3"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] =
    "%s/blob/%s/README.md" % [spec.homepage, "v#{Lifer::VERSION}"]
  spec.metadata["source_code_uri"] =
    "%s/tree/%s" % [spec.homepage, "v#{Lifer::VERSION}"]
  spec.metadata["changelog_uri"] = "%s/blob/main/CHANGELOG.md" % spec.homepage

  # Specify which files should be added to the gem when it is released. The
  # `git ls-files -z` loads the files in the RubyGem that have been added into
  # git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`
      .split("\x0")
      .reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end

  spec.bindir = "bin"
  spec.executables =
    spec.files.grep(%r{\Abin/}) { |bin_file| File.basename(bin_file) }
  spec.require_paths = ["lib"]

  spec.add_dependency "i18n", "< 2"
  spec.add_dependency "kramdown", "~> 2.4"
  spec.add_dependency "liquid", ["~> 5.6", "< 6"]
  spec.add_dependency "listen", "< 4"
  spec.add_dependency "parallel", ["~> 1.26", "< 2"]
  spec.add_dependency "puma", "< 7"
  spec.add_dependency "rack", "< 4"
  spec.add_dependency "rss", "< 1"
end
