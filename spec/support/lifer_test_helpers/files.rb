# frozen_string_literal: true

require "fileutils"
require "tmpdir"

require "lifer"

module Support::LiferTestHelpers::Files
  SPEC_ROOT = "%s/spec" % Lifer.gem_root

  # Builds a Lifer project in a temporary directory. It depends on Lifer data
  # provided inside of the `spec/support` directory and assumes any arguments
  # passed in are paths inside of that directory.
  #
  #
  # @param root [String] The relative path to any test Lifer project inside of
  #   `spec/support/`.
  # @param config_file [String] The relative path to any test Lifer config file
  #   inside of `spec/support/`
  # # @return [Lifer::Brain] A fully-functional Lifer brain. For testing purposes,
  #  but just like the real thing.
  def spec_lifer!(
    root: "root_with_entries",
    config_file: "root_with_entries/.config/lifer.yaml"
  )
    # Destroy any existing persisted Lifer project.
    #
    Lifer.class_variable_set "@@brain", nil

    temp_root = temp_root(support_file root)
    temp_config_file = File.join(temp_root, config_file.gsub(root, "")) if config_file

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

  # Given a root directory (usually within `spec/support/`), this method copies
  # all of the contents in a new temporary directory.
  #
  # @param root_directory [String] The path to the directory to be copied and
  #   temporized.
  # @return [String] The path to the temporary root directory.
  def temp_root(root_directory)
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
