require "spec_helper"

RSpec.describe Lifer::Selection::IncludedInFeeds do
  include_examples "Lifer::Selection subclass"

  describe "#entries" do
    subject { included_in_feeds_selection.entries }

    let(:included_in_feeds_selection) { described_class.generate }
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

    it "only returns entries that would be included in feeds" do
      expect(subject).not_to include html_entry
      expect(subject).to include markdown_entry
    end
  end
end
