require "spec_helper"

RSpec.describe Lifer::Collection do
  let(:collection) {
    described_class.generate name: "name", directory: directory
  }
  let(:directory) { support_file "root_with_entries/subdirectory_one" }

  describe ".generate" do
    subject {
      described_class.generate(name: :my_collection, directory: directory)
    }

    it "generates a collection" do
      expect(subject.name).to eq :my_collection
      expect(subject.entries).to contain_exactly(
        an_instance_of(Lifer::Entry::HTML),
        an_instance_of(Lifer::Entry::Markdown),
        an_instance_of(Lifer::Entry::Markdown)
      )
    end
  end

  describe "#entries" do
    subject { collection.entries }

    it "creates entries from a directory" do
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
          allow(Lifer).to receive(:gem_root).and_return("fake/gem_root")
          allow(Lifer)
            .to receive(:setting)
            .with(:layout_file, collection: collection)
            .and_return("fake/gem_root")
        end

        it { is_expected.to eq "fake/gem_root" }
      end

      context "containing the Lifer root" do
        let(:absolute_path_to_layout_file) {
          support_file "root_with_entries/.config/layouts/" \
            "layout_with_greeting.html.erb"
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
      let(:relative_path_to_layout_file) {
        support_file(
          "root_with_entries/.config/layouts/layout_with_greeting.html.erb"
        ).gsub(support_file("root_with_entries/.config/"), "")
      }
      let(:absolute_path_to_layout_file) {
        support_file "root_with_entries/.config/layouts/" \
          "layout_with_greeting.html.erb"
      }

      before do
        allow(Lifer).to receive(:config_file).and_return(
          support_file "root_with_entries/.config/lifer.yaml"
        )
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
