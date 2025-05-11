require "spec_helper"

RSpec.describe Lifer::URIStrategy::Root do
  let(:root) { temp_dir_with_files "entry.md" => nil, "subdir/sub.md" => nil }
  let(:uri_strategy) { described_class.new root: root }

  describe ".name" do
    subject { described_class.name }

    it { is_expected.to eq :root }
  end

  describe "#output_file" do
    subject { uri_strategy.output_file entry }

    let(:entry) { Lifer::Entry::Markdown.new file:, collection: }

    context "when in the root collection" do
      let(:collection) {
        Lifer::Collection.generate name: :root, directory: File.dirname(file)
      }
      let(:file) { Dir.glob("#{root}/**/entry.md").first }

      it { is_expected.to eq "entry.html" }
    end

    context "when not in the root collection" do
      let(:collection) {
        Lifer::Collection.generate name: :subdirectory_one,
          directory: File.dirname(file)
      }
      let(:file) { Dir.glob("#{root}/**/subdir/sub.md").first }

      it "still returns an output at the root" do
        expect(subject).to eq "sub.html"
      end
    end
  end

  describe "#permalink" do
    subject { uri_strategy.permalink entry }

    let(:entry) { Lifer::Entry::Markdown.new file:, collection: }

    context "when in the root collection" do
      let(:collection) {
        Lifer::Collection.generate name: :root, directory: File.dirname(file)
      }
      let(:file) { Dir.glob("#{root}/**/entry.md").first }

      it { is_expected.to eq "entry.html" }
   end

    context "when not in the root collection" do
      let(:collection) {
        Lifer::Collection.generate name: :subdirectory_one,
          directory: File.dirname(file)
      }
      let(:file) { Dir.glob("#{root}/**/subdir/sub.md").first }

      it "still returns a permalink at the root" do
        expect(subject).to eq "sub.html"
      end
    end
  end
end
