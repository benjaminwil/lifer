require "spec_helper"

RSpec.describe Lifer::Builder::SimpleHTMLFromERB do
  let(:root) { temp_root support_file("root_with_entries") }

  before do
    Lifer.brain root: root
  end

  describe ".execute" do
    subject { described_class.execute(root: root) }

    it "generates HTML for each entry" do
      entry_count = Dir.glob("#{root}/**/*.md").count

      expect { subject }
        .to change { Dir.glob("#{root}/_build/**/*.html").count }
        .from(0)
        .to(entry_count)
    end

    it "generates HTML in the correct subdirectories" do
      entry_count = Dir.glob("#{root}/subdirectory_one/**/*.md").count

      expect { subject }
        .to change {
          Dir.glob("#{root}/_build/subdirectory_one/**/*.html").count
        }
        .from(0)
        .to(entry_count)
    end

    context "when a custom layout is configured in the root settings" do
      let(:config) {
        Lifer::Config.build(
          file: support_file(
            "root_with_entries/.config/custom-root-layout-lifer.yaml"
          )
        )
      }
      let(:layout_file) {
        File.join root, ".config/layouts/layout_with_greeting.html.erb"
      }
      let(:collection_entry_file) {
        File.read File.join(
          root,
          "_build/subdirectory_one/entry_in_subdirectory.html"
        )
      }
      let(:root_collection_entry_file) {
        File.read File.join(root, "_build/tiny_entry.html")
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
          File.join root,
            ".config/layouts/layout_for_subdirectory_one_collection.html.erb"
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

    it { is_expected.to eq :simple_html_from_erb }
  end
end
