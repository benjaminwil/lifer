require "spec_helper"

RSpec.describe Lifer::Collection do
  let(:collection) {
    described_class.generate  name: "name", directory: "directory"
  }

  describe ".generate" do
    subject {
      described_class.generate(name: :my_collection, directory: directory)
    }

    let(:directory) { support_file "root_with_entries/subdirectory_one" }

    it "generates a collection" do
      expect(subject.name).to eq :my_collection
      expect(subject.entries).to include(
        an_instance_of(Lifer::Entry),
        an_instance_of(Lifer::Entry)
      )
    end
  end

  describe ".entries_from" do
    subject { described_class.entries_from(directory) }

    let(:directory) { support_file "root_with_entries/subdirectory_one" }

    it "creates entries from a directory" do
      expect(subject).to include(
        an_instance_of(Lifer::Entry),
        an_instance_of(Lifer::Entry)
      )
    end
  end

  describe "#setting" do
    subject { collection.setting(:setting_name) }

    it "delegates to the global setting method" do
      allow(Lifer).to receive(:setting).with(:setting_name, {collection: collection})

      subject

      expect(Lifer)
        .to have_received(:setting)
        .with(:setting_name, {collection: collection})
        .once
    end
  end
end
