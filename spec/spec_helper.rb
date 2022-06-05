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
    Lifer.class_variables.each do |class_variable|
      Lifer.class_variable_set class_variable.to_s, nil
    end
  end

  def temp_root(root_directory)
    Dir.mktmpdir.tap { |temp_directory|
      files = Dir
        .glob("#{root_directory}/**/*")
        .select { |file| File.file? file }
        .map { |file| [file, file.gsub(root_directory, temp_directory)] }

      files.each do |original, temp|
        FileUtils.mkdir_p File.dirname(temp)
        FileUtils.cp original, temp
      end
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

# This `fuzzy_match` custom matcher was lifted from the gem
# `rspec-match_fuzzy`. Link to source code:
#
#   https://github.com/winebarrel/rspec-match_fuzzy
#
RSpec::Matchers.define :fuzzy_match do |expected|
  expected = expected.to_s

  match do |actual|
    actual = actual.to_s

    actual.strip.gsub(/[[:blank:]]+/, '').gsub(/\n+/, "\n") ==
      expected.strip.gsub(/[[:blank:]]+/, '').gsub(/\n+/, "\n")
  end

  failure_message do |actual|
    actual = actual.to_s

    actual_normalized =
      actual
        .strip
        .gsub(/^\s+/, '')
        .gsub(/[[:blank:]]+/, "\s")
        .gsub(/\n+/, "\n")
        .gsub(/\s+$/, '')

    expected_normalized =
      expected
        .strip
        .gsub(/^\s+/, '')
        .gsub(/[[:blank:]]+/, "\s")
        .gsub(/\n+/, "\n")
        .gsub(/\s+$/, '')

    message = <<-EOS.strip
expected: #{expected_normalized.inspect}
     got: #{actual_normalized.inspect}
    EOS

    diff =
      RSpec::Expectations.differ.diff(actual_normalized, expected_normalized)

    unless diff.strip.empty?
      diff_label =
        RSpec::Matchers::ExpectedsForMultipleDiffs::DEFAULT_DIFF_LABEL

      message << "\n\n" << diff_label << diff
    end

    message
  end
end
