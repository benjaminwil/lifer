require "spec_helper"

RSpec.describe Lifer::Entry do
  let(:entry) { described_class.new(file: file) }

  describe "#text" do
    subject { entry.text }

    context "when the file exists" do
      let(:file) { support_file "root_with_entries/entry_one.md" }

      it "returns the file text contents" do
        expect(subject)
          .to start_with("# An entry")
          .and end_with("voluptate.\n")
      end
    end

    context "when the file doesn't exist" do
      let(:file) { "doesnt-exist" }

      it { is_expected.to eq nil }
    end
  end
end
