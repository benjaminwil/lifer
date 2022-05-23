require "spec_helper"

RSpec.describe Lifer::Layout do
  describe ".build" do
    subject { described_class.build(entry: entry) }

    let(:entry) { Lifer::Entry.new(file: file) }
    let(:file) { support_file "root_with_entries/entry_two.md" }

    it "renders a valid HTML document using the default template" do
      expect(subject).to eq <<~RESULT
        <html><head></head><body><h1 id="tiny">Tiny</h1><p>A testable entry.</p></body></html>
      RESULT
        .strip
    end
  end
end
