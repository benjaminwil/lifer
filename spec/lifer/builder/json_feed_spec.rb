require "spec_helper"

RSpec.describe Lifer::Builder::JSONFeed do
  let(:project) { Support::LiferTestHelpers::TestProject.new files:, config: }
  let(:files) {
    {
      "tiny_entry.md" => <<~MARKDOWN
        ---
        summary: A testable entry.
        date: Sun 01 Mar 2025 11:11:11 PDT
        updated: Sun 30 Mar 2025 14:14:14 PDT
        authors: Person 1
        external_url: https://example.com
        image: /image.png
        banner_image: /banner.png
        ---
        # Tiny

        A testable entry.
      MARKDOWN
    }
  }

  describe ".execute" do
    subject { described_class.execute root: project.brain.root }

    context "with a boolean JSON Feed configuration" do
      let(:config) { "json_feed: true" }

      it "generates a single JSON feed to the collection's name + `.json`" do
        expect { subject }
          .to change {
            Dir.glob("#{project.brain.output_directory}/**/root.json").count
          }
          .from(0)
          .to(1)
      end
    end

    context "with a simple JSON Feed configuration (filename only)" do
      let(:config) {
        <<~CONFIG
          json_feed: my-feed.json
          subdirectory_one:
            blah: blah
        CONFIG
      }

      it "generates a single JSON feed" do
        expect { subject }
          .to change {
            Dir.glob("#{project.brain.output_directory}/**/my-feed.json").count
          }
          .from(0)
          .to(1)
      end

      it "generates the correct amount of feed items" do
        # We're excluding the entries in `subdirectory_one` here.
        #
        article_count = Dir.glob("#{project.brain.root}/*.md").count

        subject

        feed_items = generated_feed_document("my-feed.json")["items"]

        expect(feed_items.count).to eq article_count
      end

      it "generates parseable article metadata correctly" do
        subject

        expect(generated_feed_document "my-feed.json").to eq(
          {
            "version" => "1.1",
            "title" => "My Lifer Weblog",
            "description" => "Just another Lifer weblog, lol...",
            "language" => "en",
            "items" => [
              {
                "authors" => [{"name" => "Person 1"}],
                "external_url" => "https://example.com",
                "id" => "https://example.com/tiny_entry.html",
                "url" => "https://example.com/tiny_entry.html",
                "title" => "Untitled Entry",
                "summary" => "A testable entry.",
                "image" => "https://example.com/image.png",
                "banner_image" => "https://example.com/banner.png",
                "date_published" => "2025-03-01 11:11:11 -0700",
                "date_modified" => "2025-03-30 14:14:14 -0700",
                "tags" => [],
                "language" => "en",
                "content_html" => "<h1 id=\"tiny\">Tiny</h1>\n\n<p>A testable entry.</p>\n"
              }
            ]
          }
        )
     end

      it "creates valid JSON" do
        subject

        feed_contents = File.read(
          Dir.glob("#{project.brain.output_directory}/**/my-feed.json").first
         )

        expect { JSON.parse feed_contents }.not_to raise_error
      end
    end

    context "when many collections are configured (filename only)" do
      let(:files) {
        {"root-entry.md" => nil, "subdirectory_one/entry.md" => nil}
      }
      let(:config) {
        <<~CONFIG
          json_feed: default.json
          subdirectory_one:
            json_feed: subdirectory-one.json
            home_page_url: https://example.com/subdir
        CONFIG
      }

      it "generates more than one RSS feed" do
        pattern = "#{project.brain.output_directory}/**/*.json"
        expect { subject }
          .to change { Dir.glob(pattern).count }.from(0).to(2)

        expect(Dir.glob(pattern).map { File.basename _1 })
          .to contain_exactly "default.json", "subdirectory-one.json"
      end
    end

    context "when many collections are configured (with unique collection-specific settings)" do
      let(:files) {
        {"root-entry.md" => nil, "subdirectory_one/entry.md" => nil}
      }
      let(:config) {
        <<~CONFIG
          json_feed: default.json
          subdirectory_one:
            json_feed:
              url: subdirectory-one.json
              home_page_url: https://example.com/subdir
        CONFIG
      }

      it "generates more than one RSS feed" do
        pattern = "#{project.brain.output_directory}/**/*.json"
        expect { subject }
          .to change { Dir.glob(pattern).count }.from(0).to(2)

        expect(Dir.glob(pattern).map { File.basename _1 })
          .to contain_exactly "default.json", "subdirectory-one.json"
      end

      it "includes the specified home page URL" do
        subject

        expect(generated_feed_document "subdirectory-one.json").to include(
          "home_page_url" => "https://example.com/subdir"
        )
      end
    end

    context "when a single collection is configured with all options" do
      let(:config) {
        <<~CONFIG
          json_feed:
            count: 1
            url: custom.json
            home_page_url: https://example.com/subdir
        CONFIG
      }
      let(:files) { {"one.md" => "One", "two.md" => "Two"} }

      it "obeys URL configuration" do
        expect { subject }
          .to change { generated_feed_document("custom.json") }
          .from(nil)
          .to(instance_of Hash)
      end

      it "obeys count configuration" do
        subject

        expect(generated_feed_document["items"].count).to eq 1
      end
    end
  end

  describe ".name" do
    subject { described_class.name }

    it { is_expected.to eq :json_feed }
  end

  # Without arguments, this grabs the contents of the first found feed. With a
  # filename argument, it grabs the first feed with the given name.
  #
  # @param filename [String] A feed filename, i.e. "my-feed.json".
  # @return [Nokogiri::XML::Document, NilClass] Either a document or nil.
  def generated_feed_document(filename = "*.json")
    document =
      Dir.glob("#{project.brain.output_directory}/**/#{filename}").first
    JSON.parse(File.read document) if document
  end
end
