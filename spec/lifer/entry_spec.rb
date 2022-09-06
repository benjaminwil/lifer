require "spec_helper"

RSpec.describe Lifer::Entry do
  let(:entry) { described_class.new(file: file) }

  describe "#body" do
    subject { entry.body }

    context "when frontmatter is present" do
      let(:file) { support_file "root_with_entries/entry_with_frontmatter.md" }

      it "excludes the frontmatter" do
        expect(subject).to start_with("# An entry")
      end
    end

    context "when frontmatter is not present" do
      let(:file) { support_file "root_with_entries/tiny_entry.md" }

      it "displays everything" do
        expect(subject)
          .to start_with("# Tiny")
          .and end_with("A testable entry.")
      end
    end
  end

  describe "#frontmatter" do
    subject { entry.frontmatter }

    context "when frontmatter is present" do
      let(:file) { support_file "root_with_entries/entry_with_frontmatter.md" }

      it { is_expected.to eq({some: "frontmatter"}) }
    end

    context "when frontmatter is not present" do
      let(:file) { support_file "root_with_entries/tiny_entry.md" }

      it { is_expected.to eq({}) }
    end
  end

  describe "#full_text" do
    subject { entry.full_text }

    context "when the file exists" do
      let(:file) { support_file "root_with_entries/tiny_entry.md" }

      it "returns the file text contents" do
        expect(subject)
          .to start_with("# Tiny")
          .and end_with("A testable entry.\n")
      end
    end

    context "when the file doesn't exist" do
      let(:file) { "doesnt-exist" }

      it { is_expected.to eq nil }
    end

    context "when the file has frontmatter" do
      let(:file) { support_file "root_with_entries/entry_with_frontmatter.md" }

      it "includes the frontmatter" do
        expect(subject).to start_with("---\n")
      end
    end
  end
end
