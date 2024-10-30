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

    context "when the layout file is a Liquid file" do
      before do
        spec_lifer! config: <<~CONFIG
          layout_file: ./layouts/layout_with_greeting.html.liquid
        CONFIG
      end

      it "builds using the correct layout" do
        subject

        entry =
          File.read(File.join spec_lifer.output_directory, "tiny_entry.html")

        expect(entry).to include "Liquid greetings!"
        expect(entry).to include "A testable entry."
      end
    end

    context "when the layout file is an unknown type of file" do
      before do
        spec_lifer! config: <<~CONFIG
          layout_file: ./layouts/unknown.zzz
        CONFIG
      end

      it "exits the program" do
        expect { subject }
          .to output(/No builder for layout file/)
          .to_stdout
          .and raise_error SystemExit
      end
    end

    context "when a custom layout is configured in the root settings" do
      before do
        spec_lifer! config: <<~CONFIG
          layout_file: ./layouts/layout_with_greeting.html.erb
          uri_strategy: simple
          subdirectory_one:
            uri_strategy: pretty
        CONFIG
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
          spec_lifer! config: <<~CONFIG
            layout_file: ./layouts/layout_with_greeting.html.erb
            uri_strategy: simple
            subdirectory_one:
              layout_file: ./layouts/layout_for_subdirectory_one_collection.html.erb
              uri_strategy: pretty
          CONFIG
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
