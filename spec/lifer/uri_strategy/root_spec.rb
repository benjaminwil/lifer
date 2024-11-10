require "spec_helper"

RSpec.describe Lifer::URIStrategy::Root do
  let(:root) { temp_root support_file("root_with_entries") }
  let(:uri_strategy) { described_class.new root: root }

  describe ".name" do
    subject { described_class.name }

    it { is_expected.to eq :root }
  end

  describe "#output_file" do
    subject { uri_strategy.output_file entry }

    let(:entry) {
      Lifer::Entry::Markdown.new file: file, collection: collection
    }

    context "when in the root collection" do
      let(:collection) {
        Lifer::Collection.generate name: :root, directory: File.dirname(file)
      }
      let(:file) { Dir.glob("#{root}/**/tiny_entry.md").first }

      it { is_expected.to eq Pathname("tiny_entry.html") }
    end

    context "when not in the root collection" do
      let(:collection) {
        Lifer::Collection.generate name: :subdirectory_one,
          directory: File.dirname(file)
      }
      let(:file) {
        Dir.glob("#{root}/**/subdirectory_one/entry_in_subdirectory.md").first
      }

      it "still returns an output at the root" do
        expect(subject).to eq Pathname("entry_in_subdirectory.html")
      end
    end
  end
end
