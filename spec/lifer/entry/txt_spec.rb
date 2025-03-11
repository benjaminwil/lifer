require "spec_helper"

RSpec.describe Lifer::Entry::TXT do
  it_behaves_like "Lifer::Entry subclass"

  describe "#title" do
    subject { entry.title }

    let(:entry) { described_class.new file:, collection: }
    let(:collection) {
      Lifer::Collection.new name: "test", directory: File.dirname(file)
    }

    context "when there is title frontmatter" do
      let(:file) { temp_file "test.txt", "---\ntitle: Title\n---" }

      it "returns the title frontmatter" do
        expect(subject).to eq "Title"
      end
    end

    context "when there is no title frontmatter" do
      let(:file) { temp_file "test.txt", "no frontmatter" }

      it "returns the output filename" do
        with_stdout_silenced do
          expect(subject).to eq "test"
        end
      end
    end
  end
end
