require "spec_helper"

RSpec.describe Lifer::Entry::Markdown do
  let(:entry) { described_class.new file: file, collection: collection }

  let(:collection) {
    Lifer::Collection.generate name: "Collection", directory: File.dirname(file)
  }

  it_behaves_like "Lifer::Entry subclass"

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

    context "when no summary is present and the body is long and contains elements" do
      let(:file) {
        temp_file "long.md", <<~MARKDOWN
          In the "realm" where dreams dance upon [ethereal](#) melodies and
          time surrenders to whispers of serenity, there lies a tapestry
          of old that looks like total shit.
        MARKDOWN
      }

      it {
        is_expected
          .to eq <<~TEXT.strip
            In the “realm” where dreams dance upon ethereal melodies and time surrenders to whispers of serenity, there lies a tapest...
         TEXT
      }
    end

    context "when no summary is present and there is a good place to truncate" do
      let(:file) {
        temp_file "long.md", <<~MARKDOWN
          Obvious truncation point is after this sentence ends. In the "realm"
          where dreams dance upon [ethereal](#) melodies and time surrenders
          to whispers of serenity, there lies a tapestry of old that looks
          like total shit.
        MARKDOWN
      }

      it {
        is_expected
          .to eq "Obvious truncation point is after this sentence ends."
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
