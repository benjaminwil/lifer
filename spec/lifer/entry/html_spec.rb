require "spec_helper"

RSpec.describe Lifer::Entry::HTML do
  it_behaves_like "Lifer::Entry subclass"

  describe "#title" do
    subject { entry.title }

    let(:collection) {
      Lifer::Collection.generate name: "Collection",
        directory: File.dirname(file)
    }
    let(:entry) { described_class.new file: file, collection: collection }
    let(:file) {
      support_file "root_with_entries/html_entry_with_layout_variables.html.erb"
    }

    it "returns the output filename" do
      with_stdout_silenced do
        expect(subject).to eq "html_entry_with_layout_variables.html"
      end
    end
  end
end
