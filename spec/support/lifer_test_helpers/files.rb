# frozen_string_literal: true

require "fileutils"
require "tmpdir"

require "lifer"

module Support::LiferTestHelpers::Files
  SPEC_ROOT = "%s/spec" % Lifer.gem_root
  DEFAULT_TEST_CONFIG = <<~CONFIG
    unregistered_setting: does nothing
    uri_strategy: simple
    subdirectory_one:
      uri_strategy: pretty
  CONFIG

  # Builds a Lifer project in a temporary directory. It depends on Lifer data
  # provided inside of the `spec/support` directory and assumes any arguments
  # passed in are paths inside of that directory.
  #
  # @param root [String] The relative path to any test Lifer project inside of
  #   `spec/support/`.
  # @param config [String] The config string is used to create a config file
  #   on the fly.
  # @return [Lifer::Brain] A fully-functional Lifer brain. For testing purposes,
  #   but just like the real thing.
  def spec_lifer!(root: "root_with_entries", config: DEFAULT_TEST_CONFIG)
    # Destroy any existing persisted Lifer project.
    #
    Lifer.class_variable_set "@@brain", nil
    temp_root = temp_root(support_file root)
    temp_config_file = temp_config(config, temp_root)

    @@spec_lifer = Lifer.brain(root: temp_root, config_file: temp_config_file)
  end

  # If `#spec_lifer!` has been previously called, this method returns
  # the`Lifer::Brain` that was set up.
  #
  # @return [LiferBrain, NilClass]
  def spec_lifer
    @@spec_lifer
  end

  # A simple helper to prefix a relative path to a support file in
  # `spec/support` into an absolute path.
  #
  # @param path_to_file [String] The path to a file.
  # @return [String] An absolute path to the given file.
  def support_file(path_to_file)
    "#{SPEC_ROOT}/support/#{path_to_file}"
  end

  # Create a temporary Lifer config file on the fly. For example:
  #
  #     temp_config(<<~MY_CONFIG)
  #       key: value
  #       collection:
  #         key: value
  #     MY_CONFIG
  #
  # The contents must be valid YAML in order for this to work as intended.
  #
  # @param contents [String] The contents of the generated YAML file.
  # @param temp_root [String] The absolute path to the Lifer root directory to
  #   be used with this temporary config file.
  # @return [String] The absolute path to the temporary config file.
  def temp_config(
    contents = DEFAULT_TEST_CONFIG,
    temp_root = temp_root(support_file "root_with_entries")
  )
    path = nil

    Dir.chdir temp_root do
      FileUtils.mkdir_p ".config"

      File.open File.join(temp_root, ".config", "temp.yaml"), "w" do |file|
        file.puts contents
        path = file.path
      end
    end

    path
  end

  # Given a root directory (usually within `spec/support/`), this method copies
  # all of the contents in a new temporary directory.
  #
  # @param root_directory [String] The path to the directory to be copied and
  #   temporized.
  # @return [String] The path to the temporary root directory.
  def temp_root(root_directory = support_file("root_with_entries"))
    Dir.mktmpdir.tap { |temp_directory|
      files = Dir
        .glob("#{root_directory}/**/*", File::FNM_DOTMATCH)
        .select { |file| File.file? file }
        .map { |file| [file, file.gsub(root_directory, temp_directory)] }

      files.each do |original, temp|
        FileUtils.mkdir_p File.dirname(temp)
        FileUtils.cp original, temp
      end
    }
  end
end
