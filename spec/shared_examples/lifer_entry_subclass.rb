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

  describe "#full_text" do
    subject { entry.full_text }

    let(:entry) { described_class.new file: file, collection: collection }
    let(:file) {
      temp_file "tiny.md", <<~MARKDOWN
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
    let(:file) { temp_file "small.md", "<p>Hello world</p>" }
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
    let(:file) { temp_file "tiny.#{described_class.output_extension}" }
    let(:collection) {
      Lifer::Collection.generate name: "Collection",
        directory: File.dirname(file)
    }

    before do
      allow(Lifer).to receive(:root).and_return(File.dirname(file))
    end

    it "responds with the path relative from root" do
      expect(subject).to eq "/tiny.#{described_class.output_extension}"
    end
  end

  describe "#permalink" do
    subject { entry.permalink }

    let(:entry) { described_class.new file: file, collection: collection }
    let(:file) { temp_file "test.#{described_class.output_extension}" }
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
end
