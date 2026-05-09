require "spec_helper"

RSpec.describe Lifer::Author do
  describe ".build_or_update" do
    subject { described_class.build_or_update(name:, url:, avatar:, entries:) }

    let(:url) { "https://example.com/optional" }
    let(:avatar) { "https://example.com/optional.png" }

    context "when the author doesn't already exist" do
      let(:name) { "doesnt-exist" }
      let(:entries) { [] }

      it "initializes a new author" do
        allow(described_class)
          .to receive(:new).with(
            name: "doesnt-exist",
            url: "https://example.com/optional",
            avatar: "https://example.com/optional.png",
            entries: []
          )
        subject
        expect(described_class)
          .to have_received(:new).with(
            name: "doesnt-exist",
            url: "https://example.com/optional",
            avatar: "https://example.com/optional.png",
            entries: []
          )
      end

      it "adds it to the author manifest" do
        expect { subject }.to change { Lifer.author_manifest.count }.by(1)
      end
    end

    context "when the author already exists" do
      let(:name) { "Already EXISTS" }

      let!(:existing_author) {
        Lifer::Author.build_or_update(name: "ALREADY Exists", entries: [])
      }

      context "and no entries are being added" do
        let(:entries) { [] }

        it { is_expected.to eq existing_author }

        it "does not add anything to the author manifest" do
          expect { subject }.not_to change { Lifer.author_manifest.count }
        end
      end

      context "and entries are being added" do
        let(:entries) {
          [Lifer::Entry.generate(file: temp_file("test.md"), collection: :whatever)]
        }

        it "updates the entries tracked on the author" do
          expect { subject }.to change { existing_author.entries.count }.by(1)
        end
      end
    end
  end

  describe "#name=" do
    subject { author.name = "A Name" }

    let(:author) {
      described_class.new name: "existing-author",
        url: nil,
        avatar: nil,
        entries: []
    }

    it "does not allow you to overwrite the name" do
      expect { subject }.to raise_error NoMethodError
    end
  end

  describe "#entries=" do
    subject { author.entries = 1234 }

    let(:author) {
      described_class.new name: "existing-author",
        url: nil,
        avatar: nil,
        entries: []
    }

    it "does not allow you to write to the entries collection directly" do
      expect { subject }.to raise_error NoMethodError
    end
  end

  describe "#avatar" do
    subject { author.avatar }

    context "when the avatar input is bad" do
      let(:author) {
        described_class.new name: "H", avatar: "", url: nil, entries: []
      }

      it "displays a helpful error message and returns nil", :aggregate_failures do
        allow(Lifer::Message)
          .to receive(:error)
          .with("utilities.ambiguous_uri_error", object_type: "Lifer::Author", uri: "")

        expect(subject).to be_nil

        expect(Lifer::Message)
          .to have_received(:error)
          .with("utilities.ambiguous_uri_error", object_type: "Lifer::Author", uri: "")
          .once
      end
    end

    context "when the avatar input is relative" do
      let(:author) {
        described_class.new name: "H", avatar: "/pic.png", url: nil, entries: []
      }

      it { is_expected.to eq "https://example.com/pic.png" }
    end

    context "when the avatar input is absolute" do
      let(:author) {
        described_class.new name: "H",
          avatar: "https://some-website.com/pic.png",
          url: nil,
          entries: []
      }

      it { is_expected.to eq "https://some-website.com/pic.png" }
    end
  end

  describe "#id" do
    subject { author.id }

    let(:author) {
      described_class.new name: "Someone's Full Name",
        avatar: nil,
        url: nil,
        entries: []
    }

    it { is_expected.to eq "someone-s-full-name" }
  end

  describe "#url" do
    subject { author.url }

    context "when the URL input is bad" do
      let(:author) {
        described_class.new name: "H", avatar: nil, url: "", entries: []
      }

      it "displays a helpful error message and returns nil", :aggregate_failures do
        allow(Lifer::Message)
          .to receive(:error)
          .with("utilities.ambiguous_uri_error", object_type: "Lifer::Author", uri: "")

        expect(subject).to be_nil

        expect(Lifer::Message)
          .to have_received(:error)
          .with("utilities.ambiguous_uri_error", object_type: "Lifer::Author", uri: "")
          .once
      end
    end

    context "when the URL input is relative" do
      let(:author) {
        described_class.new name: "H", avatar: nil, url: "/pic.png", entries: []
      }

      it { is_expected.to eq "https://example.com/pic.png" }
    end

    context "when the URL input is absolute" do
      let(:author) {
        described_class.new name: "H",
          avatar: nil,
          url: "https://some-website.com/pic.png",
          entries: []
      }

      it { is_expected.to eq "https://some-website.com/pic.png" }
    end
  end
end
