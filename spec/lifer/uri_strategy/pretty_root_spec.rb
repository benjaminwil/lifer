require "spec_helper"

RSpec.describe Lifer::URIStrategy::PrettyRoot do
  let(:root) { temp_root support_file("root_with_entries") }
  let(:uri_strategy) { described_class.new root: root }

  describe ".name" do
    subject { described_class.name }

    it { is_expected.to eq :pretty_root }
  end

  describe "#output_file" do
    subject { uri_strategy.output_file entry }

    let(:entry) {
      Lifer::Entry::Markdown.new file: file, collection: collection
    }

    context "when the entry is an index file" do
      let(:collection) {
        Lifer::Collection.generate name: :root, directory: File.dirname(file)
      }
      let(:file) { Dir.glob("#{root}/**/index.html").first }

      it "takes an `index.html` URI instead of `index/index.html`" do
        expect(subject).to eq Pathname("index.html")
      end
    end

    context "when in the root collection" do
      let(:collection) {
        Lifer::Collection.generate name: :root, directory: File.dirname(file)
      }
      let(:file) { Dir.glob("#{root}/**/tiny_entry.md").first }

      it { is_expected.to eq Pathname("tiny_entry/index.html") }
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
        expect(subject).to eq Pathname("entry_in_subdirectory/index.html")
      end
    end
  end
end
