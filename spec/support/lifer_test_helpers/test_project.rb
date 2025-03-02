# frozen_string_literal: true

require "fileutils"
require "tmpdir"

require "lifer"

# Create a Lifer project inline during a test using this class. You can define a
# list of files and their contents, as well as the contents of a Lifer
# configuration file, to be created.
#
# @example Usage
#    let(:project) {
#      Support::LiferTestHelpers::TestProject.new(files:, config:)
#    }
#    let(:files) { {"relative/path/to/entry.md" => "entry contents"} }
#    let(:config) {
#      <<~YAML
#        uri_strategy: root
#        other_collection:
#          uri_strategy: pretty
#      YAML
#    }
#
class Support::LiferTestHelpers::TestProject
  DEFAULT_TEST_CONFIG = <<~CONFIG
    unregistered_setting: does nothing
    uri_strategy: simple
    subdirectory_one:
      uri_strategy: pretty
  CONFIG

  DEFAULT_TEST_FILES = {
    "index.html" => "Contents",
    "subdirectory_one/entry.md" => "Contents"
  }

  attr_accessor :root, :config

  # This initializer does all of the work required to get the Lifer directories,
  # files, and configuration up and running. By the end, a brain has been
  # created against temporary files on your filesystem.
  #
  # If a Lifer brain had previously been created, it gets destroyed to make way
  # for the new one being created for the current test.
  #
  # @param config [String] The contents of Lifer configuration file.
  # @param files [Hash] A hash with keys referring to relative file paths and
  #   values referring to the contents of the file.
  # @param use_default_config [boolean] Skip creating a configuration file,
  #   opting to use Lifer's default configuration template instead.
  # @return [void]
  def initialize(
    config: DEFAULT_TEST_CONFIG,
    files: DEFAULT_TEST_FILES,
    use_default_config: false
  )
    # Destroy existing persisted Lifer project.
    #
    Lifer.class_variable_set "@@brain", nil

    @root = set_up_root(files)
    @config = set_up_config(config) unless use_default_config

    @@spec_lifer = Lifer.brain(root:, config_file: @config)
  end

  # Access the brain for the current test project.
  #
  # @return [Lifer::Brain] The brain!
  def brain = @@spec_lifer

  private

  def generate_file(project_root, relative_path_to_file, contents)
    path_to_file = File.join(project_root, relative_path_to_file)

    FileUtils.mkdir_p File.dirname(path_to_file)
    File.open path_to_file, "w" do |file|
      file.puts contents
    end
  end

  def set_up_config(contents)
    Dir.chdir(root) { generate_file root, ".config/lifer.yaml", contents }
  end

  def set_up_root(files)
    Dir.mktmpdir.tap { |temp_directory|
      files.each do |file, contents|
        generate_file temp_directory, file, contents
      end
    }
  end
end
