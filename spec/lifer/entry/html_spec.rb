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
    let(:file) { temp_file "html_entry_with_layout_variables.html" }

    it "returns the output filename" do
      with_stdout_silenced do
        expect(subject).to eq "html_entry_with_layout_variables"
      end
    end
  end
end
