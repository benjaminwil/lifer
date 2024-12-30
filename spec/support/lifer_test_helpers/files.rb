# frozen_string_literal: true

require "fileutils"
require "tmpdir"

require "lifer"

module Support::LiferTestHelpers::Files
  # A helper that provides the path to a temporary directory with the given
  # files in it.
  #
  # Example usage:
  #
  #    temp_dir_with_files "relative/path/to/file.md" => "contents of file",
  #      "another/file.html" => <<~HTML,
  #        <p>Hello world.</p>
  #      HTML
  #      "another/file.rb" => <<~RUBY
  #        puts "hello world"
  #      RUBY
  #
  # @overload temp_dir_with_files(path_with_contents, ...)
  #   @param path_with_contents [Object] A string key representing the path to a
  #     requested tempfile, and the value representing the file's contents (or
  #     nil).
  #   @params ... [Object] Any number of additional objects!
  #   @return [String] The path to the new temporary directory.
  def temp_dir_with_files(**paths_and_contents)
    temp_dir = Dir.mktmpdir

    Dir.chdir(temp_dir) do
      paths_and_contents.each do |filename, contents|
        absolute_path = File.join(temp_dir, filename)
        FileUtils.mkdir_p File.dirname(absolute_path)

        File.open filename, "w" do |file|
          file.puts contents || ""
        end
      end
    end

    temp_dir
  end

  # A simple helper that provides a path to a real tempfile with the given
  # contents.
  #
  # @param filename [String] The filename for the temp file.
  # @param contents [String] The contents of the temp file.
  # @return [String] The absolute path to the temp file.
  def temp_file(filename, contents = "")
    temp_dir = Dir.mktmpdir
    absolute_path = File.join(temp_dir, filename)
    FileUtils.mkdir_p File.dirname(absolute_path)

    File.open absolute_path, "w" do |file|
      file.puts contents
    end

    absolute_path
  end
end
