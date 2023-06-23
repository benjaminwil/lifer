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

  describe "#date" do
    subject { entry.date }

    context "when in Jekyll date format" do
      let(:file) {
        support_file "root_with_entries/entry_with_jekyll_date_frontmatter.md"
      }

      it { is_expected.to eq Time.new(2010, 12, 31, 9, 31, 59, "-07:00") }
    end

    context "when in Unix date format" do
      let(:file) {
        support_file "root_with_entries/entry_with_unix_date_frontmatter.md"
      }

      it { is_expected.to eq Time.new(2022, 9, 6, 11, 39, 15, "-06:00") }
    end

    context "when the date frontmatter is invalid" do
      let(:file) {
        support_file "root_with_entries/entry_with_invalid_date_frontmatter.md"
      }

      it { is_expected.to be_nil }

      it "prints an error to STDOUT" do
        expect { subject }.to output("[#{file}]: invalid date\n").to_stdout
      end
    end

    context "when there's no date metadata" do
      let(:file) { support_file "root_with_entries/tiny_entry.md" }

      it { is_expected.to be_nil }

      it "prints an error STDOUT" do
          expect { subject }
            .to output("[#{file}]: no date metadata\n").to_stdout
      end
    end

    context "when date is in filename" do
      context "and it's invalid" do
        let(:file) {
          support_file "root_with_entries/" \
            "2012-999-01-entry_with_invalid_date_in_filename.md"
        }

        it { is_expected.to be_nil }

        it "prints an error to STDOUT" do
          expect { subject }
            .to output("[#{file}]: no date metadata\n").to_stdout
        end
      end

      context "and it's valid" do
        let(:file) {
          support_file "root_with_entries/" \
            "2012-03-25-entry_with_date_in_filename.md"
        }

        it { is_expected.to eq Time.new(2012, 3, 25, 0, 0, 0, "+00:00") }
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

      it "raises an error" do
        expect { subject }
          .to raise_error StandardError, "file \"doesnt-exist\" does not exist"
      end

    end

    context "when the file has frontmatter" do
      let(:file) { support_file "root_with_entries/entry_with_frontmatter.md" }

      it "includes the frontmatter" do
        expect(subject).to start_with("---\n")
      end
    end
  end
end
