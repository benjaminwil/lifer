# frozen_string_literal: true

require "fileutils"
require "tmpdir"

require "lifer"

class Support::LiferTestHelpers::FilesV2
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

  def initialize(
    config: DEFAULT_TEST_CONFIG,
    files: DEFAULT_TEST_FILES
  )
    # Destroy existing persisted Lifer project.
    #
    Lifer.class_variable_set "@@brain", nil

    @root = set_up_root(files)
    @config = set_up_config(config)

    @@spec_lifer = Lifer.brain(root:, config_file: @config)
  end

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
