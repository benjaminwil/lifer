require "spec_helper"

RSpec.describe Lifer::Brain do
  let(:brain) { described_class.init root: root }
  let(:root) { temp_root support_file("root_with_entries") }

  describe ".init" do
    subject { described_class.init root: root, config_file: "path/to/file" }

    # This is a bit of a hack. What I'm trying to do is ensure the `MovieReviews`
    # class is being loaded when `Lifer::Brain.init` is called, to assert that
    # user-provided Ruby files are being loaded. But the reason this hack is
    # required is because the file loads are not being *unloaded* between test
    # runs. I am not sure what the nicest way to do this would be.
    #
    # `MovieReviews`, by the way, is included in the `root_with_entries` test
    # project.
    #
    before do
      if Object.constants.include? :MovieReviews
        Object.send :remove_const, :MovieReviews
      end
    end

    it { is_expected.to be_an_instance_of Lifer::Brain }

    it "loads Ruby files within the Lifer root directory" do
      expect { subject }
        .to change { defined? MovieReviews }
        .from(nil)
        .to("constant")
    end
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
          .with(*["html", "rss"], root: root)
          .once
      end
    end

    context "when using a custom configuration file" do
      let(:config) {
        config_file = temp_config(<<~CONFIG)
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
          config_file = temp_config(<<~CONFIG)
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
              "execute: No such file or directory - not_an_executable_program"
        end
      end

      context "when steps are provided per environment" do
        let(:config) {
          config_file = temp_config(<<~CONFIG)
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

          allow(Open3)
            .to receive(:popen3)
            .with("echo \"serve command\"")
            .and_return([double, dummy_stdout, double, double])
          allow(Open3).to receive(:popen3).with("echo \"build command\"")
            .and_return([double, dummy_stdout, double, double])

          subject

          expect(Open3)
            .not_to have_received(:popen3).with("echo \"serve command\"")
          expect(Open3)
            .to have_received(:popen3).with("echo \"build command\"").once
        end
      end

      context "when the given prebuild steps are acceptable" do
        let(:config) {
          config_file = temp_config(<<~CONFIG)
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

          allow(Open3)
            .to receive(:popen3)
            .with("echo \"command 1\"")
            .and_return([double, dummy_stdout, double, double])
          allow(Open3).to receive(:popen3).with("echo \"command 2\"")
            .and_return([double, dummy_stdout, double, double])

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
      let(:brain) {
        spec_lifer! root: "root_with_entries", config: <<~CONFIG
          subdirectory_one:
            uri_strategy: pretty

          selections:
            - movie_reviews
        CONFIG
      }

      it "returns all collections and selections" do
        expect(subject).to contain_exactly(
          an_instance_of(Lifer::Collection),
          an_instance_of(Lifer::Collection),
          an_instance_of(MovieReviews)
        )
      end
    end

    context "when the user has not included custom selections" do
      let(:brain) { spec_lifer! root: "root_with_nothing", config: "" }

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

      let(:directory_entries) {
        Dir
          .glob("#{root}/**/*")
          .reject { |entry| entry.include? "_build" }
          .select { |entry| File.file? entry }
          .select { |entry| Lifer::Entry.supported? entry }
      }

      it "lists all entries" do
        expect(subject).to be_an_instance_of Set
        expect(subject.count).to eq directory_entries.count
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

      let(:directory_entries) {
        Dir
          .glob("#{root}/**/*")
          .reject { |entry| entry.include? "_build" }
          .select { |entry| File.file? entry }
          .select { |entry| Lifer::Entry.supported? entry }
      }

      it "lists all entries" do
        expect(subject).to be_an_instance_of Set
        expect(subject.count).to eq directory_entries.count
      end
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
end
