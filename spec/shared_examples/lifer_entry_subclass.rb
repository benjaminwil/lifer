RSpec.shared_examples "Lifer::Entry subclass" do
  describe ".include_in_feeds" do
    subject { described_class.include_in_feeds }

    it "equals true or false" do
      expect(subject).to eq(true).or eq(false)
    end
  end

  describe ".output_extension" do
    subject { described_class.output_extension }

    it "has an output file extension defined" do
      expect(subject).not_to be_nil
    end
  end

  describe ".manifest" do
    subject { described_class.manifest }

    it "returns a list of all currently-existing entries" do
      expect {
        Support::LiferTestHelpers::TestProject.new

        # This test sets up one entry of each supported type in order to work as
        # a shared example for any `Lifer::Entry` subclass.
        #
        collection = "whatever"
        Lifer::Entry.generate(file: temp_file("my-markdown.md"), collection:)
        Lifer::Entry.generate(file: temp_file("my-html.html.erb"), collection:)
        Lifer::Entry.generate(file: temp_file("my-text.txt"), collection:)
      }
        .to change { described_class.manifest }
        .from([])
        .to([instance_of(described_class)])
    end
  end

  describe "#authors" do
    subject { entry.authors }

    let(:entry) { described_class.new file: file, collection: collection }
    let(:collection) {
      Lifer::Collection.generate name: "Collection",
        directory: File.dirname(file)
    }

    context "when frontmatter for both 'authors' and 'author exist" do
      let(:file) {
        temp_entry_subclass "author-and-authors", <<~CONTENTS
            ---
            author: singular author
            authors: [many, authors]
            ---
          CONTENTS
      }

      it { is_expected.to eq ["singular author"] }
    end

    context "when frontmatter for 'authors' exists" do
      let(:file) {
        temp_entry_subclass "entry-with-authors", <<~CONTENTS
            ---
            authors: [all of, the authors]
            ---
          CONTENTS
      }

      it { is_expected.to eq ["all of", "the authors"] }
    end

    context "when frontmatter for 'author' exists" do
      let(:file) { temp_entry_subclass "author", "---\nauthor: one author\n---" }

      it { is_expected.to eq ["one author"] }
    end

    context "when no frontmatter for 'authors' or 'author' exists" do
      let(:file) { temp_entry_subclass "no-frontmatter" }

      it { is_expected.to be_empty }
    end
  end

  describe "#body" do
    subject { entry.body }

    let(:entry) { described_class.new file:, collection: }
    let(:collection) {
      Lifer::Collection.generate name: "Collection",
        directory: File.dirname(file)
    }

    context "when frontmatter is present" do
      let(:file) {
        temp_entry_subclass "frontmatter", <<~CONTENT
            ---
            author: an author
            ---

            # An entry
          CONTENT
      }

      it "excludes the frontmatter" do
        expect(subject).to start_with("# An entry")
      end
    end

    context "when frontmatter is not present" do
      let(:file) {
        temp_entry_subclass "no-frontmatter", <<~CONTENT
            # Tiny
            A testable entry.
          CONTENT
      }

      it "displays everything" do
        expect(subject)
          .to start_with("# Tiny")
          .and end_with("A testable entry.")
      end
    end
  end

  describe "#frontmatter" do
    subject { entry.frontmatter }

    let(:entry) { described_class.new file:, collection: }
    let(:collection) {
      Lifer::Collection.generate name: "Collection",
        directory: File.dirname(file)
    }

    context "when frontmatter is present" do
      let(:file) {
        temp_entry_subclass "frontmatter", <<~CONTENT
            ---
            some: frontmatter
            title: Entry with Frontmatter
            ---
          CONTENT
      }

      it {
        is_expected.to eq(
          some: "frontmatter",
          title: "Entry with Frontmatter"
        )
      }
    end

    context "when frontmatter is not present" do
      let(:file) { temp_entry_subclass "no-frontmatter" }

      it { is_expected.to eq({}) }
    end
  end

  describe "#full_text" do
    subject { entry.full_text }

    let(:entry) { described_class.new file: file, collection: collection }
    let(:file) {
      temp_entry_subclass "tiny", <<~MARKDOWN
          # Tiny
          A testable entry.
        MARKDOWN
    }
    let(:collection) {
      Lifer::Collection.generate name: "Collection",
        directory: File.dirname(file)
    }

    context "when the file exists" do
      it "returns the file text contents" do
        expect(subject)
          .to start_with("# Tiny")
          .and end_with("A testable entry.\n")
      end
    end
  end

  describe "#to_html" do
    subject { entry.to_html }

    let(:entry) { described_class.new file: file, collection: collection }
    let(:file) { temp_entry_subclass "small", "<p>Hello world</p>" }
    let(:collection) {
      Lifer::Collection.generate name: "Collection",
        directory: File.dirname(file)
    }

    it "is implemented" do
      expect { subject }.not_to raise_error
    end
  end

  describe "#path" do
    subject { entry.path }

    let(:entry) { described_class.new file: file, collection: collection }
    let(:file) { temp_entry_subclass "entry" }
    let(:collection) {
      Lifer::Collection.generate name: "Collection",
        directory: File.dirname(file)
    }

    before do
      allow(Lifer).to receive(:root).and_return(File.dirname(file))
    end

    it "responds with the path relative from root" do
      expect(subject).to eq "/entry.#{described_class.output_extension}"
    end
  end

  describe "#permalink" do
    subject { entry.permalink }

    let(:entry) { described_class.new file: file, collection: collection }
    let(:file) { temp_entry_subclass "test" }
    let(:collection) {
      Lifer::Collection.generate name: "Collection",
        directory: File.dirname(file)
    }

    before do
      allow(Lifer).to receive(:root).and_return(File.dirname(file))
    end

    it "responds with a well-formed URL" do
      with_stdout_silenced do
        expect(subject).to eq "https://example.com/test." \
          "#{described_class.output_extension}"
      end
    end
  end

  describe "#published_at" do
    subject { entry.published_at }

    let(:entry) { described_class.new file:, collection: }
    let(:collection) {
      Lifer::Collection.generate name: "Collection",
        directory: File.dirname(file)
    }

    context "when in Jekyll date format" do
      let(:file) {
        temp_entry_subclass "jekyll-date-format", <<~CONTENT
          ---
          date: 2010-12-31 09:31:59 -0700
          ---
         CONTENT
      }

      it { is_expected.to eq Time.new(2010, 12, 31, 9, 31, 59, "-07:00") }
    end

    context "when in Unix date format" do
      let(:file) {
        temp_entry_subclass "unix-date-format", <<~CONTENT
            ---
            date: Tue  6 Sep 2022 11:39:15 MDT
            ---
          CONTENT
      }

      it { is_expected.to eq Time.new(2022, 9, 6, 11, 39, 15, "-06:00") }
    end

    context "when the date frontmatter is invalid" do
      let!(:file) {
        temp_entry_subclass "invalid-date-format", <<~CONTENT
            ---
            date: invalid-date
            ---
          CONTENT
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

    context "when there's no `published_at` metadata" do
      let!(:file) { temp_entry_subclass "no-date" }

      it "returns a default date" do
        expect(subject).to be_a Time
      end

      it "prints an error STDOUT" do
        allow(ENV).to receive(:[]).with("LIFER_ENV").and_return("not-test")

        expect { subject }
          .to output("[#{file}]: no `published_at` metadata\n").to_stdout
      end
    end

    context "when date is in filename" do
      context "and it's invalid" do
        let!(:file) { temp_entry_subclass "2012-999-01-entry-title" }

        it "returns a default date" do
          expect(subject).to be_a Time
        end

        it "prints an error to STDOUT" do
          allow(ENV).to receive(:[]).with("LIFER_ENV").and_return("not-test")

          expect { subject }
            .to output("[#{file}]: no `published_at` metadata\n").to_stdout
        end
      end

      context "and it's valid" do
        let(:file) { temp_entry_subclass "2012-03-25-entry-title" }

        it { is_expected.to eq Time.new(2012, 3, 25, 0, 0, 0, "+00:00") }
      end
    end
  end

  describe "#summary" do
    subject { entry.summary }

    let(:entry) { described_class.new file:, collection: }
    let(:collection) {
      Lifer::Collection.generate name: "Collection",
        directory: File.dirname(file)
    }

    context "when a summary is present" do
      let(:file) {
        temp_entry_subclass "with-summary", "---\nsummary: the summary\n---"
      }

      it { is_expected.to eq "the summary" }
    end

    context "when no summary or entry body are present" do
      let(:file) { temp_file "blank.md", "" }

      it { is_expected.to be_nil }
    end
  end

  describe "#tags" do
    subject { entry.tags }

    let(:entry) { described_class.new file:, collection: }
    let(:collection) {
      Lifer::Collection.generate name: "Collection",
        directory: File.dirname(file)
    }

    context "when there is tag frontmatter" do
      let(:file) {
        temp_entry_subclass "with-tags", <<~CONTENT
          ---
          tags: tag1, tag2, tag3
          ---
        CONTENT
      }

      it "returns a collection of tags", :aggregate_failures do
        expect(subject).to contain_exactly instance_of(Lifer::Tag),
          instance_of(Lifer::Tag),
          instance_of(Lifer::Tag)
        expect(subject.map(&:name)).to eq ["tag1", "tag2", "tag3"]
      end
    end

    context "when there is no tag frontmatter" do
      let(:file) { temp_entry_subclass "without-tags" }

      it { is_expected.to be_empty }
    end
  end

  describe "#title" do
    subject { entry.title }

    let(:entry) { described_class.new file:, collection: }
    let(:file) { temp_entry_subclass "blank" }
    let(:collection) {
      Lifer::Collection.generate name: "Collection",
        directory: File.dirname(file)
    }

    it "is implemented" do
      expect { subject }.not_to raise_error(NotImplementedError)
    end
  end

  describe "#to_html" do
    subject { entry.to_html }

    let(:entry) { described_class.new file:, collection: }
    let(:file) {
      temp_entry_subclass "entry-with-frontmatter", <<~CONTENT
        ---
        title: Some frontmatter
        ---
      CONTENT
    }
    let(:collection) {
      Lifer::Collection.generate name: "Collection",
        directory: File.dirname(file)
    }

    it "is implemented" do
      expect { subject }.not_to raise_error(NotImplementedError)
    end

    it "does not output frontmatter" do
      expect(subject).not_to start_with "---\ntitle: Some frontmatter\n---"
    end
  end

  # Wraps our `#temp_file` test helper so that these shared examples easily work
  # with any entry subclass.
  #
  # For more information see `Support::LiferTestHelpers::Files#temp_file`.
  #
  # @param filename [String] The name (sans file extension) to the temp file.
  # @param contents [String] The contents of the temp file.
  # @return [String] The absolute path to the temp file.
  def temp_entry_subclass(name, contents = "Contents...")
    extension = described_class.input_extensions.first
    filename = "%s.%s" % [name, extension]
    temp_file filename, contents
  end
end
