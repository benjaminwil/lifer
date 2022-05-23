require "spec_helper"

RSpec.describe Lifer::Collection do
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
end
