require "spec_helper"

RSpec.describe Lifer::Brain do
  let(:brain) { described_class.init(root: root) }
  let(:root) { temp_root support_file("root_with_entries") }

  describe "#build!" do
    subject { brain.build! }

    it "executes a build" do
      allow(Lifer::Builder::HTML).to receive(:execute).with(root: root)

      subject

      expect(Lifer::Builder::HTML).to have_received(:execute).with(root: root)
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

    it "creates collections as described in the .config/lifer.yaml" do
      expect(subject).to contain_exactly(
        an_instance_of(Lifer::Collection),
        an_instance_of(Lifer::Collection)
      )
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

        brain.build!
      end

      let(:root) { temp_root support_file("root_with_entries") }

      let(:directory_entry_count) {
        Dir
          .glob("#{root}/**/*.md")
          .select { |entry| File.file? entry }
          .count
      }

      it "lists all entries" do
        expect(subject).to be_an_instance_of Set
        expect(subject.count).to eq directory_entry_count
      end
    end
  end
end