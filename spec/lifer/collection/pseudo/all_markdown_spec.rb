require "spec_helper"

RSpec.describe Lifer::Collection::Pseudo::AllMarkdown do
  include_examples "Lifer::Collection::Pseudo subclass"

  describe "#entries" do
    subject { all_markdown_pseudo_collection.entries }

    let(:all_markdown_pseudo_collection) { described_class.generate }
    let(:html_entry) {
      Lifer::Entry::HTML.new file: "not-real-html", collection: nil
    }
    let(:markdown_entry) {
      Lifer::Entry::Markdown.new file: "not-real-md", collection: nil
    }

    before do
      spec_lifer!

      Lifer.entry_manifest << html_entry
      Lifer.entry_manifest << markdown_entry
    end

    it "only returns markdown entries" do
      expect(subject).not_to include html_entry
      expect(subject).to include markdown_entry
    end
  end
end
