require "spec_helper"

RSpec.describe Lifer::URIStrategy::Pretty do
  let(:root) {
    temp_dir_with_files "entry.md" => nil,
      "subdir/subsubdir/sub_entry.md" => nil
  }
  let(:uri_strategy) { described_class.new root: root }

  describe ".name" do
    subject { described_class.name }

    it { is_expected.to eq :pretty }
  end

  describe "#output_file" do
    subject { uri_strategy.output_file entry }

    let(:collection) {
      Lifer::Collection.generate name: "Collection",
        directory: File.dirname(file)
    }
    let(:entry) { Lifer::Entry::Markdown.new file:, collection: }

    context "in the root directory" do
      let(:file) { Dir.glob("#{root}/**/entry.md").first }

      it { is_expected.to eq Pathname("entry/index.html") }
    end

    context "in a subdirectory" do
      let(:file) { Dir.glob("#{root}/**/sub_entry.md").first }

      it "returns the output file path" do
        expect(subject).to eq Pathname("subdir/subsubdir/sub_entry/index.html")
      end
    end
  end
end
