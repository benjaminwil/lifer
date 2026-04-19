require "spec_helper"

RSpec.describe Lifer::Asset do
  describe ".build_or_update" do
    subject { described_class.build_or_update(url:, entries:) }

    let(:url) { "https://example.com/image.png" }
    let(:entries) { [] }

    context "when the asset doesn't already exist" do
      it "initializes a new asset" do
        allow(described_class)
          .to receive(:new).with(
            url: "https://example.com/image.png",
            entries: []
          )
        subject
        expect(described_class)
          .to have_received(:new).with(
            url: "https://example.com/image.png",
            entries: []
          )
          .once
      end

      it "adds it to the asset manifest" do
        expect { subject }.to change { Lifer.asset_manifest.count }.by(1)
      end
    end

    context "when the asset already exists" do
      let!(:existing_asset) {
        Lifer::Asset.build_or_update url: "https://example.com/image.png",
          entries: []
      }

      context "and no entries are being added" do
        let(:entries) { [] }

        it { is_expected.to eq existing_asset }

        it "does not add anything to the asset manifest" do
          expect { subject }.not_to change { Lifer.asset_manifest.count }
        end
      end

      context "and entries are being added" do
        let(:entries)  {
          [Lifer::Entry.generate(file: temp_file("test.md"), collection: :whatever)]
        }

        it "updates the entries tracked on the asset" do
           expect { subject }.to change { existing_asset.entries.count }.by(1)
        end
      end
    end
  end

  describe "#match?" do
    subject { asset.match?(url: "/given-url.mp3") }

    context "when the given URL matches the current asset's URL" do
      let(:asset) { described_class.new(url: "/given-url.mp3", entries: []) }

      it { is_expected.to eq true }
    end

    context "when the given URL does not match the current asset's URL" do
      let(:asset) { described_class.new(url: "/other.mp3", entries: []) }

      it { is_expected.to eq false }
    end
  end

  describe "#url" do
    let(:asset) { described_class.new url: "/haha.png", entries: [] }

    context "given a non-default host" do
      subject { asset.url host: "https://asdf.com" }

      it { is_expected.to eq "https://asdf.com/haha.png" }
    end

    context "given no host" do
      subject { asset.url }

      it { is_expected.to eq "https://example.com/haha.png" }
    end
  end
end
