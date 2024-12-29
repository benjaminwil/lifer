require "spec_helper"

RSpec.describe Lifer::Builder do
  let(:root) { temp_root support_file("root_with_entries") }

  describe ".all" do
    subject { described_class.all }

    it "returns all builders by name" do
      expect(subject).to contain_exactly :html, :rss, :txt
    end
  end

  describe ".build!" do
    subject { described_class.build! *list_of_builders, root: root }

    let(:list_of_builders) { ["rss"] }

    before do
      # Do not allow any builders to actually build files to an output directory
      # in the scope of these tests.
      #
      Lifer::Builder.send(:descendants).each do |subclass|
        allow(subclass)
          .to receive(:execute)
          .and_return(instance_double subclass)
      end
    end

    it "builds only the builders specified in the list of builders" do
      subject

      expect(Lifer::Builder::HTML)
        .not_to have_received(:execute).with(root: root)

      expect(Lifer::Builder::RSS).to have_received(:execute).with(root: root)
    end
  end

  describe ".prebuild!" do
    subject { described_class.prebuild! *list_of_commands, root: root }

    context "when a given command is invalid" do
      let(:list_of_commands) { ["echo 'this one is okay'", "not_executable"] }

      it "raises an error" do
        with_stdout_silenced do
          expect { subject }.to raise_error RuntimeError, "Lifer failed to "   \
            "complete building... A prebuild step failed to execute: No such " \
            "file or directory - not_executable\n"
          end
      end
    end

    context "when all commands are valid, executable commands" do
      let(:list_of_commands) { ["echo 'do almost nothing'"] }

      it "raises no errors" do
        with_stdout_silenced do
          expect { subject }.not_to raise_error
        end
      end

      it "outputs to STDOUT" do
        expect { subject }.to output(<<~OUTPUT).to_stdout
          echo 'do almost nothing'
          do almost nothing
        OUTPUT
      end
    end
  end

  describe ".find" do
    subject { described_class.find name }

    context "when a builder with the given name exists" do
      let(:name) { :html }

      it { is_expected.to eq Lifer::Builder::HTML }
    end

    context "when a builder with the given name does not exist" do
      let(:name) { :doesntexist }

      it "raises an error" do
        expect { subject }
          .to raise_error StandardError, "no class with name \"doesntexist\""
      end
    end
  end

  describe ".name" do
    subject { described_class.name }

    it { is_expected.to eq :builder }
  end
end
