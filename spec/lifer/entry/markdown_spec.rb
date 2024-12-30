require "spec_helper"

RSpec.describe Lifer::Entry::Markdown do
  let(:entry) { described_class.new file: file, collection: collection }

  let(:collection) {
    Lifer::Collection.generate name: "Collection", directory: File.dirname(file)
  }

  it_behaves_like "Lifer::Entry subclass"

  describe "#authors" do
    subject { entry.authors }

    context "when frontmatter for both 'authors' and 'author exist" do
      let(:file) {
        temp_file "entry-with-author-and-authors.md", <<~MARKDOWN
          ---
          author: singular author
          authors: [many, authors]
          ---
        MARKDOWN
      }

      it { is_expected.to eq ["singular author"] }
    end

    context "when frontmatter for 'authors' exists" do
      let(:file) {
        temp_file "entry-with-authors.md", <<~MARKDOWN
            ---
            authors: [all of, the authors]
            ---
          MARKDOWN
      }

      it { is_expected.to eq ["all of", "the authors"] }
    end

    context "when frontmatter for 'author' exists" do
      let(:file) { temp_file "author.md", "---\nauthor: one author\n---" }

      it { is_expected.to eq ["one author"] }
    end

    context "when no frontmatter for 'authors' or 'author' exists" do
      let(:file) { temp_file "blank.md" }

      it { is_expected.to be_empty }
    end
  end

  describe "#body" do
    subject { entry.body }

    context "when frontmatter is present" do
      let(:file) {
        temp_file "frontmatter.md", <<~MARKDOWN
            ---
            author: an author
            ---

            # An entry
          MARKDOWN
      }

      it "excludes the frontmatter" do
        expect(subject).to start_with("# An entry")
      end
    end

    context "when frontmatter is not present" do
      let(:file) {
        temp_file "no-frontmatter.md", <<~MARKDOWN
            # Tiny
            A testable entry.
          MARKDOWN
      }

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
        temp_file "jekyll-date-format.md", <<~MARKDOWN
          ---
          date: 2010-12-31 09:31:59 -0700
          ---
         MARKDOWN
      }

      it { is_expected.to eq Time.new(2010, 12, 31, 9, 31, 59, "-07:00") }
    end

    context "when in Unix date format" do
      let(:file) {
        temp_file "unix-date-format.md", <<~MARKDOWN
            ---
            date: Tue  6 Sep 2022 11:39:15 MDT
            ---
          MARKDOWN
      }

      it { is_expected.to eq Time.new(2022, 9, 6, 11, 39, 15, "-06:00") }
    end

    context "when the date frontmatter is invalid" do
      let!(:file) {
        temp_file "invalid-date-format.md", <<~MARKDOWN
            ---
            date: invalid-date
            ---
          MARKDOWN
      }

      it "returns a default date" do
        expect(subject).to be_a Time
      end

      it "prints an error to STDOUT" do
        allow(ENV).to receive(:[]).with("LIFER_ENV").and_return("not-test")

        expect { subject }
          .to output("\e[31mERR: [#{file}]: invalid date\e[0m\n")
          .to_stdout
      end
    end

    context "when there's no date metadata" do
      let!(:file) { temp_file "no-date.md" }

      it "returns a default date" do
        expect(subject).to be_a Time
      end

      it "prints an error STDOUT" do
        allow(ENV).to receive(:[]).with("LIFER_ENV").and_return("not-test")

        expect { subject }
          .to output("[#{file}]: no date metadata\n").to_stdout
      end
    end

    context "when date is in filename" do
      context "and it's invalid" do
        let!(:file) { temp_file "2012-999-01-entry-title.md" }

        it "returns a default date" do
          expect(subject).to be_a Time
        end

        it "prints an error to STDOUT" do
          allow(ENV).to receive(:[]).with("LIFER_ENV").and_return("not-test")

          expect { subject }
            .to output("[#{file}]: no date metadata\n").to_stdout
        end
      end

      context "and it's valid" do
        let(:file) { temp_file "2012-03-25-entry-title.md" }

        it { is_expected.to eq Time.new(2012, 3, 25, 0, 0, 0, "+00:00") }
      end
    end
  end

  describe "#frontmatter" do
    subject { entry.frontmatter }

    context "when frontmatter is present" do
      let(:file) {
        temp_file "frontmatter.md", <<~MARKDOWN
            ---
            some: frontmatter
            title: Entry with Frontmatter
            ---
          MARKDOWN
      }

      it {
        is_expected.to eq(
          some: "frontmatter",
          title: "Entry with Frontmatter"
        )
      }
    end

    context "when frontmatter is not present" do
      let(:file) { temp_file "no-frontmatter.md" }

      it { is_expected.to eq({}) }
    end
  end

  describe "#summary" do
    subject { entry.summary }

    context "when a summary is present" do
      let(:file) {
        temp_file "with-summary.md", "---\nsummary: the summary\n---"
      }

      it { is_expected.to eq "the summary" }
    end

    context "when no summary is present and the body is short" do
      let(:file) { temp_file "short.md", "Short body text." }

      it { is_expected.to eq "Short body text." }
    end

    context "when the summary is present and the body is long" do
      let(:file) {
        temp_file "long.md", <<~MARKDOWN
          In the realm where dreams dance upon ethereal melodies and
          time surrenders to whispers of serenity, there lies a tapestry
          of old that looks like total shit.
        MARKDOWN
      }

      it {
        is_expected
 	        .to eq "In the realm where dreams dance upon ethereal melodies and " \
	          "time surrenders to whispers of serenity, there lies a tapestry..."
      }
    end

    context "when no summary or entry body are present" do
      let(:file) { temp_file "blank.md", "" }

      it { is_expected.to be_nil }
    end
  end

  describe "#title" do
    subject { entry.title }

    context "when an entry title is set in the frontmatter" do
      let(:file) { temp_file "frontmatter.md", "---\ntitle: My Title\n---" }

      it { is_expected.to eq "My Title" }
    end

    context "when an entry title is not set in the frontmatter" do
      let(:file) { temp_file "blank.md" }

      it "uses the default title according to the current Lifer configuration" do
        with_stdout_silenced do
          expect(subject).to eq "Untitled Entry"
        end
      end
    end
  end
end
