require "spec_helper"

RSpec.describe Lifer::URIStrategy::PrettyYYYYMMDD do
  let(:root) {
    temp_dir_with_files "2012-03-25_with_date.md" => nil,
      "entry.md" => nil,
      "subdir/subsubdir/sub_entry.md" => nil
  }
  let(:uri_strategy) { described_class.new root: root }

  describe ".name" do
    subject { described_class.name }

    it { is_expected.to eq :pretty_yyyy_mm_dd }
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
      let(:file) { Dir.glob("#{root}/**/entry.md").first }

      it { is_expected.to eq "entry/index.html" }
    end

    context "in a subdirectory" do
      let(:file) { Dir.glob("#{root}/**/sub_entry.md").first }

      it "returns the output file path" do
        expect(subject).to eq "subdir/subsubdir/sub_entry/index.html"
      end
    end

    context "when the filename includes the date" do
      let(:file) { Dir.glob("#{root}/**/2012-03-25_with_date.md").first }

      it "returns the output file path without the date" do
        expect(subject).to eq "with_date/index.html"
      end
    end
  end

  describe "#permalink" do
    subject { uri_strategy.permalink entry }

    let(:collection) {
      Lifer::Collection.generate name: "Collection",
        directory: File.dirname(file)
    }
    let(:entry) {
      Lifer::Entry::Markdown.new file: file, collection: collection
    }

    context "in the root directory" do
      let(:file) { Dir.glob("#{root}/**/entry.md").first }

      it { is_expected.to eq "entry" }
    end

    context "in a subdirectory" do
      let(:file) { Dir.glob("#{root}/**/sub_entry.md").first }

      it { is_expected.to eq "subdir/subsubdir/sub_entry" }
    end

    context "when the filename includes the date" do
      let(:file) { Dir.glob("#{root}/**/2012-03-25_with_date.md").first }

      it { is_expected.to eq "with_date" }
    end
  end
end
