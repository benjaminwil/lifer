require "spec_helper"

RSpec.describe Lifer::Collection do
  before do
    spec_lifer!
  end

  let(:collection) {
    described_class.generate name: "name", directory: directory
  }
  let(:directory) { "#{spec_lifer.root}/subdirectory_one" }

  describe ".generate" do
    subject {
      described_class.generate(name: :my_collection, directory: directory)
    }

    it "generates a collection" do
      expect(subject.name).to eq :my_collection
    end

    it "immediately generates all entries for the collection" do
      expect(subject.entries).to contain_exactly(
        an_instance_of(Lifer::Entry::HTML),
        an_instance_of(Lifer::Entry::Markdown),
        an_instance_of(Lifer::Entry::Markdown)
      )
    end
  end

  describe "#entries" do
    subject { collection.entries }

    it "includes entries from a directory" do
      expect(subject).to contain_exactly(
        an_instance_of(Lifer::Entry::HTML),
        an_instance_of(Lifer::Entry::Markdown),
        an_instance_of(Lifer::Entry::Markdown)
      )
    end
  end

  describe "#layout_file" do
    subject { collection.layout_file }

    context "when the setting is an absolute path" do
      context "containing the gem root" do
        before do
          allow(Lifer).to receive(:gem_root).and_return("/fake/gem_root")
          allow(Lifer)
            .to receive(:setting)
            .with(:layout_file, collection: collection)
            .and_return("/fake/gem_root")
        end

        it { is_expected.to eq "/fake/gem_root" }
      end

      context "containing the Lifer root" do
        let(:absolute_path_to_layout_file) {
          "#{spec_lifer.root}/.config/layouts/layout_with_greeting.html.erb"
        }

        before do
          allow(Lifer)
            .to receive(:setting)
            .with(:layout_file, collection: collection)
            .and_return(absolute_path_to_layout_file)
        end

        it { is_expected.to eq absolute_path_to_layout_file }
      end
    end

    context "when the setting is a relative path" do
      let(:absolute_path_to_layout_file) {
        "#{spec_lifer.root}/.config/layouts/layout_with_greeting.html.erb"
      }
      let(:relative_path_to_layout_file) {
        absolute_path_to_layout_file.gsub("#{spec_lifer.root}/.config/", "")
      }

      before do
        allow(Lifer)
          .to receive(:setting)
          .with(:layout_file, collection: collection)
          .and_return(relative_path_to_layout_file)
      end

      it { is_expected.to eq absolute_path_to_layout_file }
    end
  end

  describe "#setting" do
    subject { collection.setting(:setting_name) }

    it "delegates to the global setting method" do
      allow(Lifer).to receive(:setting).with(:setting_name, {collection: collection})

      subject

      expect(Lifer)
        .to have_received(:setting)
        .with(:setting_name, {collection: collection})
        .once
    end
  end
end
