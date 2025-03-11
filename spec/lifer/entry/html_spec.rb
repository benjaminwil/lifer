require "spec_helper"

RSpec.describe Lifer::Entry::HTML do
  it_behaves_like "Lifer::Entry subclass"

  let(:entry) { described_class.generate collection:, file: }

  describe "#title" do
    subject { entry.title }

    let(:collection) {
      Lifer::Collection.generate name: "Collection",
        directory: File.dirname(file)
    }

    context "when there is title frontmatter" do
      let(:file) { temp_file "test.html", "---\ntitle: Title\n---" }

      it "returns the title frontmatter" do
        expect(subject).to eq "Title"
      end
    end

    context "when there is no title frontmatter" do
      let(:file) { temp_file "test.html", "no frontmatter" }

      it "returns the output filename" do
        with_stdout_silenced do
          expect(subject).to eq "test"
        end
      end
    end
  end
end
