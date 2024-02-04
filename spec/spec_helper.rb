# frozen_string_literal: true

require "debug"

require_relative "shared_examples"
require_relative "support"

RSpec.configure do |config|
  # Use the built-in `documentation` formatter for runs.
  config.add_formatter :documentation

  config.after(:each) do
    # Ensure that the special `@@brain` class variable is always null before
    # each test run. This will avoid order-dependent test failures.
    #
    Lifer.class_variable_set "@@brain", nil
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

  # Provide helper methods for initializing test Lifer projects without
  # littering garbage files all over the developer's filesystem.
  #
  config.include Support::LiferTestHelpers::Files
end
