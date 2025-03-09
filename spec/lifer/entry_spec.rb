require "spec_helper"

RSpec.describe Lifer::Entry do
  let(:collection) { nil }

  describe ".generate" do
    subject { described_class.generate file: file, collection: collection }

    context "when the file doesn't exist" do
      let(:file) { "doesnt-exist" }

      it "raises an error" do
        expect { subject }
          .to raise_error StandardError, "file \"doesnt-exist\" does not exist\n"
      end
    end

    context "when the file uses an unsupported extension" do
      let(:file) { temp_file "does-not-exist.zzz" }

      it "skips the entry" do
        expect(subject).to be_nil
      end
    end

    context "when the file uses a supported HTML extension" do
      let(:file) { temp_file "subdir/sub-entry.html" }

      it "delegates to the proper subclass" do
        allow(Lifer::Entry::HTML).to receive(:new)

        subject

        expect(Lifer::Entry::HTML)
          .to have_received(:new)
          .with(file: file, collection: nil)
          .once
      end

      it "adds the entry to the entry manifest" do
        expect { subject }
          .to change { described_class.manifest }
          .from([])
          .to([instance_of(Lifer::Entry::HTML)])
      end
    end

    context "when the file uses a supported Markdown extension" do
      let(:file) { temp_file "markdown.md" }

      it "delegates to the proper subclass" do
        allow(Lifer::Entry::Markdown).to receive(:new)

        subject

        expect(Lifer::Entry::Markdown)
          .to have_received(:new)
          .with(file: file, collection: nil)
          .once
      end

      it "adds the entry to the entry manifest" do
        expect { subject }
          .to change { described_class.manifest }
          .from([])
          .to([instance_of(Lifer::Entry::Markdown)])
      end
    end

    context "when the file includes tags in its fronmatter" do
      let(:file) {
        temp_file "markdown.md", <<~MARKDOWN
          ---
          tags:
            - tag1
            - tag2
          ---
        MARKDOWN
      }

      it "generates the tags", :aggregate_failures do
        expect { subject }.to change { Lifer.tag_manifest.count }.by(2)

        expect(subject.tags.map(&:name)).to eq ["tag1", "tag2"]
      end
    end
  end

  describe ".manifest" do
    subject { described_class.manifest }

    it "returns a list of all currently-existing entries" do
      expect {
        Support::LiferTestHelpers::TestProject.new

        described_class.generate(
          file: temp_file("entry.md"),
          collection: "whatever"
        )
      }
        .to change { described_class.manifest }
        .from([])
        .to([instance_of(Lifer::Entry::Markdown)])
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
