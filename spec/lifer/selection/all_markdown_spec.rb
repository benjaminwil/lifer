require "spec_helper"

RSpec.describe Lifer::Selection::AllMarkdown do
  include_examples "Lifer::Selection subclass"

  describe "#entries" do
    subject { all_markdown_selection.entries }

    let(:all_markdown_selection) { described_class.generate }
    let(:html_entry) {
      Lifer::Entry::HTML.new file: "not-real-html", collection: nil
    }
    let(:markdown_entry) {
      Lifer::Entry::Markdown.new file: "not-real-md", collection: nil
    }

    before do
      Support::LiferTestHelpers::TestProject.new

      Lifer.entry_manifest << html_entry
      Lifer.entry_manifest << markdown_entry
    end

    it "only returns markdown entries" do
      expect(subject).not_to include html_entry
      expect(subject).to include markdown_entry
    end
  end
end
