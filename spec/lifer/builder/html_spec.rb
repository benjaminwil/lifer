require "spec_helper"

RSpec.describe Lifer::Builder::HTML do
  before do
    spec_lifer!
  end

  describe ".execute" do
    subject { described_class.execute(root: spec_lifer.root) }

    it "generates HTML for each entry" do
      entry_files = Dir.glob("#{spec_lifer.root}/**/*.*")
        .select { |entry| Lifer::Entry.supported? entry }

      expect { subject }
        .to change {
          Dir.glob("#{spec_lifer.output_directory}/**/*.html").count
        }
        .from(0)
        .to(entry_files.count)
    end

    it "generates HTML in the correct subdirectories" do
      entry_count = Dir.glob("#{spec_lifer.root}/subdirectory_one/**/*.*").count

      expect { subject }
        .to change {
          Dir.glob("#{spec_lifer.output_directory}/subdirectory_one/**/*.html")
            .count
        }
        .from(0)
        .to(entry_count)
    end

    context "when a custom layout is configured in the root settings" do
      before do
        spec_lifer! config_file: "root_with_entries/.config/" \
          "custom-root-layout-lifer.yaml"
      end

      it "builds using the correct layout" do
        subject

        collection_entry =
          File.read File.join(
            spec_lifer.output_directory,
            "subdirectory_one/entry_in_subdirectory/index.html"
          )
        root_collection_entry =
          File.read File.join(spec_lifer.output_directory, "tiny_entry.html")

        expect(collection_entry).to include "Greetings!"
        expect(root_collection_entry).to include "Greetings!"
      end

      context "when a custom layout is configured for a collection" do
        before do
          spec_lifer! config_file: "root_with_entries/.config/" \
            "all-custom-layouts.yaml"
        end

        it "builds using all the correct layouts" do
          subject

          collection_entry =
            File.read File.join(
              spec_lifer.output_directory,
              "subdirectory_one/entry_in_subdirectory/index.html"
            )
          root_collection_entry =
            File.read File.join(spec_lifer.output_directory, "tiny_entry.html")

          expect(collection_entry).not_to include "Greetings!"
          expect(collection_entry)
            .to include "Layout for Subdirectory One"

          expect(root_collection_entry).to include "Greetings!"
          expect(root_collection_entry)
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
