# frozen_string_literal: true

require "lifer"
require "fileutils"
require "tmpdir"

module Lifer::FileHelpers
  def support_file(path_to_file)
    "%s/support/%s" % [File.dirname(__FILE__), path_to_file]
  end

  def use_support_config(path_to_root)
    Lifer.class_variable_set(
      "@@config",
      Lifer::Config.build(file: support_file(path_to_root))
    )
  end

  def lose_support_config
    Lifer.class_variable_set("@@config", nil)
    Lifer.class_variable_set("@@manifest", nil)
  end

  def temp_root(root_directory)
    Dir.mktmpdir.tap { |temp_directory|
      files = Dir
        .glob("#{root_directory}/**/*")
        .select { |file| File.file? file }

      FileUtils.cp_r files, temp_directory
    }
  end
end

RSpec.configure do |config|
  config.after(:each) do
    lose_support_config
  end

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include Lifer::FileHelpers
end
