# frozen_string_literal: true

module Support::LiferTestHelpers::Files
  SPEC_ROOT = "%s/spec" % Lifer.gem_root

  def support_file(path_to_file)
    "#{SPEC_ROOT}/support/#{path_to_file}"
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
