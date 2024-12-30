require "spec_helper"

RSpec.describe Lifer::Entry::HTML do
  it_behaves_like "Lifer::Entry subclass"

  let(:entry) { described_class.generate collection:, file: }

  describe "#date" do
    subject { entry.date }

    let(:collection) {
      Lifer::Collection.generate name: "Collection",
        directory: File.dirname(file)
    }
    let(:file) { temp_file "file.html" }

    it { is_expected.to be_a Time }
  end

  describe "#title" do
    subject { entry.title }

    let(:collection) {
      Lifer::Collection.generate name: "Collection",
        directory: File.dirname(file)
    }
    let(:file) { temp_file "test.html" }

    it "returns the output filename" do
      with_stdout_silenced do
        expect(subject).to eq "test"
      end
    end
  end
end
