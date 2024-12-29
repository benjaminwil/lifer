require "spec_helper"

RSpec.describe Lifer::Entry::TXT do
  it_behaves_like "Lifer::Entry subclass"

  describe ".generate" do
    subject { described_class.generate(file:, collection:) }

    let(:file) { temp_file "text_file.txt" }
    let(:collection) {
      Lifer::Collection.new name: "test", directory: File.dirname(file)
    }
  end
end
