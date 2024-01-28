require "spec_helper"

RSpec.describe Lifer::Entry do
  describe ".generate" do
    subject { described_class.generate file: file, collection: collection }

    let(:collection) { nil }

    context "when the file doesn't exist" do
      let(:file) { "doesnt-exist" }

      it "raises an error" do
        expect { subject }
          .to raise_error StandardError, "file \"doesnt-exist\" does not exist"
      end
    end

    context "when the file uses an unsupported extension" do
      let(:file) {
        support_file "root_with_entries/" \
          "entry_with_unsupported_file_extension.zzz"
      }

      it "skips the entry" do
        expect(subject).to be_nil
      end
    end

    context "when the file uses a supported HTML extension" do
      let(:file) {
        support_file "root_with_entries/subdirectory_one/" \
          "page_entry_in_subdirectory.html.erb"
      }

      it "delegates to the proper subclass" do
        allow(Lifer::Entry::HTML).to receive(:new)

        subject

        expect(Lifer::Entry::HTML)
          .to have_received(:new)
          .with(file: file, collection: nil)
          .once
      end
    end

    context "when the file uses a supported Markdown extension" do
      let(:file) {
        support_file "root_with_entries/subdirectory_one/" \
          "entry_in_subdirectory.md"
      }

      it "delegates to the proper subclass" do
        allow(Lifer::Entry::Markdown).to receive(:new)

        subject

        expect(Lifer::Entry::Markdown)
          .to have_received(:new)
          .with(file: file, collection: nil)
          .once
      end
    end
  end

  describe ".supported?" do
    subject { described_class.supported? filename, extensions }

    let(:filename) { "filename.zazzy" }

    context "when the filename is supported" do
      let(:extensions) { ["html", "md", "zazzy"] }

      it { is_expected.to eq true }
    end

    context "when the filename is not supported" do
      let(:extensions) { ["html"] }

      it { is_expected.to eq false }
    end
  end
end
