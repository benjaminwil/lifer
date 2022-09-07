require "spec_helper"

RSpec.describe Lifer::URIStrategy::Pretty do
  let(:root) { temp_root support_file("root_with_entries") }
  let(:uri_strategy) { described_class.new(root: root) }

  describe "#name" do
    subject { uri_strategy.name }

    it { is_expected.to eq "pretty" }
  end

  describe "#output_file" do
    subject { uri_strategy.output_file entry }

    let(:entry) { Lifer::Entry.new(file: source_file) }

    context "in the root directory" do
      let(:source_file) { Dir.glob("#{root}/**/tiny_entry.md").first }

      it { is_expected.to eq Pathname("tiny_entry/index.html") }
    end

    context "in a subdirectory" do
      let(:source_file) {
        Dir.glob("#{root}/**/entry_in_sub_subdirectory_one.md").first
      }

      it "returns the output file path" do
        expect(subject).to eq Pathname("subdirectory_one/" \
          "sub_subdirectory_one/" \
            "entry_in_sub_subdirectory_one/" \
              "index.html")
      end
    end
  end
end
