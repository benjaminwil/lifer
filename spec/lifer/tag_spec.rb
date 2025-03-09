require "spec_helper"

RSpec.describe Lifer::Tag do
  describe ".build_or_update" do
    subject { described_class.build_or_update(name:, entries:) }

    context "when the tag doesn't already exist" do
      let(:name) { "doesnt-exist" }
      let(:entries) { [] }

      it "initializes a new tag" do
        allow(described_class)
          .to receive(:new).with(name: "doesnt-exist", entries: [])
        subject
        expect(described_class)
          .to have_received(:new).with(name: "doesnt-exist", entries: [])
      end

      it "adds it to the tag manifest" do
        expect { subject }.to change { Lifer.tag_manifest.count }.by(1)
      end
    end

    context "when the tag already exists" do
      let(:name) { "already-exists" }

      let!(:existing_tag) {
        Lifer::Tag.build_or_update(name: "already-exists", entries: [])
      }

      context "and no entries are being added" do
        let(:entries) { [] }

        it { is_expected.to eq existing_tag }

        it "does not add anything to the tag manifest" do
          expect { subject }.not_to change { Lifer.tag_manifest.count }
        end
      end

      context "and entries are being added" do
        let(:entries) {
          [Lifer::Entry.generate(file: temp_file("test.md"), collection: :whatever)]
        }

        it "updates the entries tracked on the tag" do
          expect { subject }.to change { existing_tag.entries.count }.by(1)
        end
      end
    end
  end

  describe "#entries=" do
    subject { tag.entries = 1234 }

    let(:tag) { described_class.new name: "existing-tag", entries: [] }

    it "does not allow you to write to the entries collection directly" do
      expect { subject }.to raise_error NoMethodError
    end
  end
end
