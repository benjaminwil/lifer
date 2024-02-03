# frozen_string_literal: true

require "lifer"

require "debug"
require "fileutils"
require "tmpdir"

require_relative "shared_examples"
require_relative "support"

RSpec.configure do |config|
  # Use the built-in `documentation` formatter for runs.
  config.add_formatter :documentation

  config.after(:each) do
    lose_support_config
  end

  # If RSpec runs on somethign other than TTY, try to display colours.
  config.color_mode = :on

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include Support::LiferTestHelpers::Files
end
