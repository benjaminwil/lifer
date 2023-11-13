require "spec_helper"

RSpec.describe Lifer::Builder::HTML do
  let(:directory) { temp_root support_file("root_with_entries") }

  before do
    allow(Lifer)
      .to receive(:brain)
      .and_return(Lifer::Brain.init(root: directory))
  end

  describe ".execute" do
    subject { described_class.execute(root: directory) }

    it "generates HTML for each entry" do
      entry_count = Dir.glob("#{directory}/**/*.md").count

      expect { subject }
        .to change { Dir.glob("#{directory}/_build/**/*.html").count }
        .from(0)
        .to(entry_count)
    end

    it "generates HTML in the correct subdirectories" do
      entry_count = Dir.glob("#{directory}/subdirectory_one/**/*.md").count

      expect { subject }
        .to change {
          Dir.glob("#{directory}/_build/subdirectory_one/**/*.html").count
        }
        .from(0)
        .to(entry_count)
    end

    context "when a custom layout is configured in the root settings" do
      let(:config) { Lifer::Config.build file: config_file }
      let(:config_file) {
        support_file "root_with_entries/.config/custom-root-layout-lifer.yaml"
      }
      let(:layout_file) {
        support_file File.join "root_with_entries",
          ".config",
          "layouts",
          "layout_with_greeting.html.erb"
      }
      let(:collection_entry_file) {
        File.read File.join(
          directory,
          "_build",
          "subdirectory_one",
          "entry_in_subdirectory.html"
        )
      }
      let(:root_collection_entry_file) {
        File.read File.join(directory, "_build", "tiny_entry.html")
      }

      it "builds using the correct layout" do
        allow(Lifer::Config).to receive(:build).and_return(config)
        allow(config)
          .to receive(:settings)
          .and_return({layout_file: layout_file})

        subject

        expect(collection_entry_file).to include "Greetings!"
        expect(root_collection_entry_file).to include "Greetings!"
      end

      context "when a custom layout is configured for a collection" do
        let(:collection_layout_file) {
          support_file File.join "root_with_entries",
            ".config",
            "layouts",
            "layout_for_subdirectory_one_collection.html.erb"
        }

        it "builds using all the correct layouts" do
          allow(Lifer::Config).to receive(:build).and_return(config)
          allow(config)
            .to receive(:settings)
            .and_return({
              layout_file: layout_file,
              subdirectory_one: {layout_file: collection_layout_file}
            })

          subject

          expect(collection_entry_file).not_to include "Greetings!"
          expect(collection_entry_file)
            .to include "Layout for Subdirectory One"

          expect(root_collection_entry_file).to include "Greetings!"
          expect(root_collection_entry_file)
            .not_to include "Layout for Subdirectory One"
        end
      end
    end
  end

  describe ".name" do
    subject { described_class.name }

    it { is_expected.to eq :html }
  end
end
