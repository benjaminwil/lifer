require "spec_helper"

RSpec.describe Lifer::Brain do
  let(:brain) { described_class.init root: root }
  let(:root) {
    temp_dir_with_files "entry.md" => <<~MARKDOWN
      ---
      tags: one, two, thre
      ---
    MARKDOWN
  }

  describe ".init" do
    subject { described_class.init root: root, config_file: "path/to/file" }

    it { is_expected.to be_an_instance_of Lifer::Brain }
  end

  describe "#build!" do
    subject {
      with_stdout_silenced do
        brain.build!
      end
    }

    before do
      allow(Lifer::Builder).to receive(:build!)
    end

    it "cleans up any existing output directory" do
      allow(FileUtils).to receive(:rm_r).with(Pathname "#{root}/_build")

      subject

      expect(FileUtils).to have_received(:rm_r).with(Pathname "#{root}/_build")
    end

    it "recreates the output directory" do
      allow(FileUtils).to receive(:mkdir_p).with(Pathname "#{root}/_build")

      subject

      expect(FileUtils)
        .to have_received(:mkdir_p)
        .with(Pathname "#{root}/_build")
    end

    context "when using a default configuration file" do
      it "executes a build with the default set of builders" do
        with_stdout_silenced do
          subject
        end

        expect(Lifer::Builder)
          .to have_received(:build!)
          .with(*["html", "rss", "txt"], root: root)
          .once
      end
    end

    context "when using a custom configuration file" do
      let(:config) {
        config_file = temp_file("lifer.yaml", <<~CONFIG)
          global:
            output_directory: "haha"
            build:
              - rss
        CONFIG

        Lifer::Config.build file: config_file
      }

      it "executes with the configured set of builders only" do
        allow(Lifer::Config).to receive(:build).and_return config

        subject

        expect(Lifer::Builder)
          .to have_received(:build!)
          .with(*["rss"], root: root)
          .once
      end
    end

    context "when prebuild steps are provided" do
      context "when the given prebuild steps error out" do
        let(:config) {
          config_file = temp_file("temp.yaml", <<~CONFIG)
            global:
              prebuild:
                - not_an_executable_program
          CONFIG

          Lifer::Config.build file: config_file
        }

        it "provides a reasonable error message" do
          allow(Lifer::Config).to receive(:build).and_return config

          expect {
            with_stdout_silenced do
              subject
            end
          }.to raise_error RuntimeError,
            "Lifer failed to complete building... A prebuild step failed to " \
              "execute: No such file or directory - not_an_executable_program\n"
        end
      end

      context "when steps are provided per environment" do
        let(:config) {
          config_file = temp_file("temp.yaml", <<~CONFIG)
            global:
              prebuild:
                serve:
                  - echo "serve command"
                build:
                  - echo "build command"
          CONFIG

          Lifer::Config.build file: config_file
        }

        it "shells out to execute each command for the current environment" do
          allow(Lifer::Config).to receive(:build).and_return config

          dummy_stdout = instance_double(IO, readlines: ["output"])
          dummy_stderr = instance_double(IO, readlines: [])

          allow(Open3)
            .to receive(:popen3)
            .with("echo \"serve command\"")
            .and_return([double, dummy_stdout, dummy_stderr, double])
          allow(Open3).to receive(:popen3).with("echo \"build command\"")
            .and_return([double, dummy_stdout, dummy_stderr, double])

          subject

          expect(Open3)
            .not_to have_received(:popen3).with("echo \"serve command\"")
          expect(Open3)
            .to have_received(:popen3).with("echo \"build command\"").once
        end
      end

      context "when the given prebuild steps are acceptable" do
        let(:config) {
          config_file = temp_file("temp.yaml", <<~CONFIG)
            global:
              prebuild:
                - echo "command 1"
                - echo "command 2"
          CONFIG

          Lifer::Config.build file: config_file
        }

        it "shells out to execute each prebuild step" do
          allow(Lifer::Config).to receive(:build).and_return config

          dummy_stdout = instance_double(IO, readlines: ["output"])
          dummy_stderr = instance_double(IO, readlines: [])

          allow(Open3)
            .to receive(:popen3)
            .with("echo \"command 1\"")
            .and_return([double, dummy_stdout, dummy_stderr, double])
          allow(Open3).to receive(:popen3).with("echo \"command 2\"")
            .and_return([double, dummy_stdout, dummy_stderr, double])

          subject

          expect(Open3)
            .to have_received(:popen3).with("echo \"command 1\"").once
          expect(Open3)
            .to have_received(:popen3).with("echo \"command 2\"").once
        end
      end
    end
  end

  describe "#config" do
    subject { brain.config }

    let(:config_object) { instance_double Lifer::Config }

    it "provides a config object" do
      allow(Lifer::Config)
        .to receive(:build)
        .and_return(config_object)

       expect(subject).to eq config_object
    end
  end

  describe "#collections" do
    subject { brain.collections }

    context "when the user has included their own selection class" do
      let(:files) {
        {
          "entry.md" => "Root entry",
          "subdirectory_one/entry.md" => "Collection entry",
          ".config/movie_reviews.rb" => <<~RUBY
            class MovieReviews < Lifer::Selection
              def entries
                @entries ||=
                  Lifer::Entry::Markdown.all.select { |entry|
                    entry.frontmatter[:tags]&.include?("review")
                  }
              end
            end
          RUBY
        }
      }
      let(:brain) {
        project =
          Support::LiferTestHelpers::TestProject.new(config: <<~CONFIG, files:)
            subdirectory_one:
              uri_strategy: pretty

            selections:
              - movie_reviews
          CONFIG

        project.brain
      }

      before do
        # The "movie_reviews" selection depends on user-provided Ruby files
        # having been loaded.
        #
        brain.require_user_provided_ruby_files!
      end

      it "returns all collections and selections" do
        expect(subject).to contain_exactly(
          an_instance_of(Lifer::Collection),
          an_instance_of(Lifer::Collection),
          an_instance_of(MovieReviews)
        )
      end
    end

    context "when the user has not included custom selections" do
      let(:brain) {
        Support::LiferTestHelpers::TestProject
          .new(files: {}, config: "")
          .brain
      }

      it "returns all collections and selections" do
        Thing = Lifer::Selection::AllMarkdown
        Object.send :remove_const, :Thing

        expect(subject).to contain_exactly(
          an_instance_of(Lifer::Collection),
          an_instance_of(Lifer::Selection::AllMarkdown),
          an_instance_of(Lifer::Selection::IncludedInFeeds)
        )
      end
    end
  end

  describe "#tag_manifest" do
    subject { brain.tag_manifest }

    context "when fresh" do
      it { is_expected.to be_an_instance_of Set }
    end

    context "after a build" do
      before do
        allow(Lifer).to receive(:brain).and_return(brain)

        with_stdout_silenced do
          brain.build!
        end
      end

      it { is_expected.to be_an_instance_of Set }

      it "has generated all entry tags", :aggregate_failures do
        expect(subject.count).to eq 3
        expect(subject.all? { _1.is_a? Lifer::Tag }).to eq true
      end
    end
  end

  describe "#entry_manifest" do
    subject { brain.entry_manifest }

    context "when fresh" do
      it { is_expected.to be_an_instance_of Set }
    end

    context "after a build" do
      before do
        allow(Lifer).to receive(:brain).and_return(brain)

        with_stdout_silenced do
          brain.build!
        end
      end

      it "lists all entries" do
        expect(subject).to be_an_instance_of Set

        input_files = directory_entries_for(root)
          .map { _1.gsub Lifer::Utilities.file_extension(_1), "" }
        output_files = subject.map(&:file).map(&:to_s)
          .map { _1.gsub Lifer::Utilities.file_extension(_1), "" }

        expect(output_files).to contain_exactly(*input_files),
          "This failure indicates that the input files and output files are " \
          "out of sync for some reason. Perhaps the `#directory_entries` " \
          "needs to be refactored to better reflect the intended manifest " \
          "contents."
      end
    end
  end

  describe "#manifest" do
    subject { brain.manifest }

    context "when fresh" do
      it { is_expected.to be_an_instance_of Set }
    end

    context "after a build" do
      before do
        allow(Lifer).to receive(:brain).and_return(brain)

        with_stdout_silenced do
          brain.build!
        end
      end

      it "lists all entries" do
        expect(subject).to be_an_instance_of Set

        input_files = directory_entries_for(root)
          .map { _1.gsub Lifer::Utilities.file_extension(_1), "" }
        output_files =
          subject.map { _1.gsub Lifer::Utilities.file_extension(_1), "" }

        expect(output_files).to contain_exactly(*input_files),
          "This failure indicates that the input files and output files are " \
          "out of sync for some reason. Perhaps the `#directory_entries` " \
          "needs to be refactored to better reflect the intended manifest " \
          "contents."
      end
    end
  end

  describe "#require_user_provided_ruby_files!" do
    subject { brain.require_user_provided_ruby_files! }

    let(:root) {
      File.dirname temp_file("movie_reviews.rb", <<~RUBY)
        class MovieReviews < Lifer::Selection
          def entries
            @entries ||=
              Lifer::Entry::Markdown.all.select { |entry|
                entry.frontmatter[:tags]&.include?("review")
              }
          end
        end
      RUBY
    }

    # This is a bit of a hack. What I'm trying to do is ensure the `MovieReviews`
    # class is being loaded. But we also need to ensure the file is *unloaded*
    # between test runs. There may be a better way to do this, but... whatever?
    #
    # `MovieReviews`, by the way, is included in the `root_with_entries` test
    # project.
    #
    before do
      if Object.constants.include? :MovieReviews
        Object.send :remove_const, :MovieReviews
      end
    end

    it "loads Ruby files within the Lifer root directory" do
      expect { subject }
        .to change { defined? MovieReviews }
        .from(nil)
        .to("constant")
    end
  end

  describe "#setting" do
    subject { brain.setting(:some_argument) }

    let(:config) { instance_double Lifer::Config }

    it "delegates to the config object" do
      allow(Lifer::Config).to receive(:build).and_return(config)
      allow(config)
        .to receive(:setting)
        .with(:some_argument, {collection_name: nil, strict: false})

      subject

      expect(config)
        .to have_received(:setting)
        .with(:some_argument, {collection_name: nil, strict: false})
        .once
    end
  end

  def directory_entries_for(root)
    Dir
      .glob("#{root}/**/*")
      .reject { |entry| entry.match? /\/_(build|layouts|partials)/ }
      .select { |entry| File.file? entry }
      .select { |entry| Lifer::Entry.supported? entry }
  end
end
