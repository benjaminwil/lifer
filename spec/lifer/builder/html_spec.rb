require "spec_helper"

RSpec.describe Lifer::Builder::HTML do
  let(:project) { Support::LiferTestHelpers::TestProject.new files:, config: }

  describe ".execute" do
    subject { described_class.execute(root: project.root) }

    let(:config) { nil }
    let(:files) {
      {
        "subdirectory_one/entry.md" => nil,
        "tiny_entry.md" => nil,
        "text_file.txt" => nil
      }
    }

    it "generates HTML for each entry" do
      expect { subject }
        .to change {
          Dir.glob("#{project.brain.output_directory}/**/*.html").count
        }
        .from(0)
        .to(2)
    end

    it "does not generate non-HTML output files (like `.txt` files)" do
      expect { subject }
        .not_to change {
          Dir.glob("#{project.brain.output_directory}/**/*.txt").count
        }
    end

    it "errors out when an there's a file conflict" do
      File.open("#{project.brain.output_directory}/tiny_entry.html", "w") {
        _1.write "Pre-existing file."
      }

      expect { subject }.to raise_error(
        RuntimeError,
        /Cannot build HTML file because.* already exists/
      )
    end

    it "generates HTML in the correct subdirectories" do
      expect { subject }
        .to change {
          Dir
            .glob("#{project.brain.output_directory}/subdirectory_one/**/*.html")
            .count
        }
        .from(0)
        .to(1)
    end

    context "when the layout file is a Liquid file" do
      let(:config) {
        <<~CONFIG
          layout_file: ./layouts/layout.html.liquid
        CONFIG
      }
      let(:files) {
        {
          ".config/layouts/layout.html.liquid" => <<~LAYOUT,
            {% render "_partials/header" with entry: entry %}
            {{ content }}
          LAYOUT
          "_partials/header.html.liquid" => <<~PARTIAL,
            Header From Partial for "{{ entry.title }}"

            The authors of this article are {{ entry.frontmatter.authors }}
          PARTIAL
          "tiny_entry.md" => <<~CONTENT
            ---
            authors: Good Person, Great Human
            ---

            A testable entry.
          CONTENT
        }
      }

      it "builds using the correct layout" do
        subject

        entry =
          File.read(File.join project.brain.output_directory, "tiny_entry.html")

        expect(entry).to include "Header From Partial for \"Untitled Entry\""
        expect(entry).to include "A testable entry."
      end

      it "supports frontmatter" do
        subject

        entry =
          File.read(File.join project.brain.output_directory, "tiny_entry.html")
        expect(entry)
          .to include "The authors of this article are Good Person, Great Human"
      end
    end

    context "when the layout file is an unknown type of file" do
      let(:config) {
        <<~CONFIG
          layout_file: ./layouts/unknown.zzz
        CONFIG
      }

      it "exits the program" do
        expect { subject }.to raise_error(
          RuntimeError,
          "No builder for layout file `./layouts/unknown.zzz` " \
            "with type `.zzz`. Aborting!"
        )
      end
    end

    context "when a custom layout is configured in the root settings" do
      let(:config) {
        <<~CONFIG
          layout_file: ./layouts/good_layout.html.erb
          uri_strategy: simple
          subdirectory_one:
            uri_strategy: pretty
        CONFIG
      }
      let(:files) {
        {
          ".config/layouts/good_layout.html.erb" => "Greetings! <%= content %>",
          "subdirectory_one/entry_in_subdirectory.md" => nil,
          "tiny_entry.md" => nil
        }
      }

      it "builds using the correct layout" do
        subject

        collection_entry =
          File.read File.join(
            project.brain.output_directory,
            "subdirectory_one/entry_in_subdirectory/index.html"
          )
        root_collection_entry =
          File.read File.join(project.brain.output_directory, "tiny_entry.html")

        expect(collection_entry).to include "Greetings!"
        expect(root_collection_entry).to include "Greetings!"
      end

      context "when a custom layout is configured for a collection" do
        let(:config) {
          <<~CONFIG
            layout_file: ./layouts/simple.html.erb
            uri_strategy: simple
            subdirectory_one:
              layout_file: ./layouts/collection.html.erb
              uri_strategy: pretty
          CONFIG
        }
        let(:files) {
          {
            ".config/layouts/simple.html.erb" => "Greetings! <%= content %>",
            ".config/layouts/collection.html.erb" =>
              "Layout for Subdirectory One\n <%= content %>",
            "subdirectory_one/entry_in_subdirectory.md" => nil,
            "tiny_entry.md" => nil
          }
        }

        it "builds using all the correct layouts" do
          subject

          collection_entry =
            File.read File.join(
              project.brain.output_directory,
              "subdirectory_one/entry_in_subdirectory/index.html"
            )
          root_collection_entry =
            File.read File.join(project.brain.output_directory, "tiny_entry.html")

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
