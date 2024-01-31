require "spec_helper"

RSpec.describe Lifer::URIStrategy::Simple do
  let(:root) { temp_root support_file("root_with_entries") }
  let(:uri_strategy) { described_class.new root: root }

  describe ".name" do
    subject { described_class.name }

    it { is_expected.to eq :simple }
  end

  describe "#output_file" do
    subject { uri_strategy.output_file entry }

    let(:collection) {
      Lifer::Collection.generate name: "Collection",
        directory: File.dirname(file)
    }
    let(:entry) {
      Lifer::Entry::Markdown.new file: file, collection: collection
    }

    context "in the root directory" do
      let(:file) { Dir.glob("#{root}/**/tiny_entry.md").first }

      it { is_expected.to eq Pathname("tiny_entry.html") }
    end

    context "in a subdirectory" do
      let(:file) {
        Dir.glob("#{root}/**/entry_in_sub_subdirectory_one.md").first
      }

      it "returns the output file path" do
        expect(subject).to eq Pathname("subdirectory_one/" \
          "sub_subdirectory_one/" \
            "entry_in_sub_subdirectory_one.html")
      end
    end
  end
end
