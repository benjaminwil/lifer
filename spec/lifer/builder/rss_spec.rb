require "nokogiri"

require "spec_helper"

RSpec.describe Lifer::Builder::RSS do
  let(:project) { Support::LiferTestHelpers::TestProject.new files:, config: }
  let(:files) {
    {
      "tiny_entry.md" => <<~MARKDOWN
        ---
        summary: A testable entry.
        ---
        # Tiny

        A testable entry.
      MARKDOWN
    }
  }

  describe ".execute" do
    subject { described_class.execute root: project.brain.root }

    context "with a boolean RSS configuration" do
      let(:config) { "rss: true" }

      it "generates a single a single RSS feed to the collection's name + `.xml`" do
        expect { subject }
          .to change {
            Dir.glob("#{project.brain.output_directory}/**/root.xml").count
          }
          .from(0)
          .to(1)
      end
    end

    context "with a simple RSS configuration (filename only)" do
      let(:config) {
        <<~CONFIG
          rss: my-feed.xml
          subdirectory_one:
            blah: blah
        CONFIG
      }

      it "generates a single RSS feed" do
        expect { subject }
          .to change {
            Dir.glob("#{project.brain.output_directory}/**/my-feed.xml").count
          }
          .from(0)
          .to(1)
      end

      it "generates the correct amount of feed items" do
        # We're excluding the entries in `subdirectory_one` here.
        #
        article_count = Dir.glob("#{project.brain.root}/*.md").count

        subject

        feed_items = generated_feed_document("my-feed.xml").xpath "//item"

        expect(feed_items.count).to eq article_count
      end

      it "generates parseable article metadata correctly" do
        subject

        generated_feed = generated_feed_document "my-feed.xml"

        managing_editor = generated_feed.xpath "//managingEditor"

        # "Admin" being the default site author. "editor@null.invalid" being our
        # provided default editor email address.
        expect(managing_editor.text).to eq "editor@null.invalid (Admin)"

        entry = generated_feed.xpath("//item").css("link")
          .detect { _1.text == "https://example.com/tiny_entry.html" }
          .parent
        expect(text_from entry, :title).to eq "Untitled Entry"
        expect(text_from entry, :description).to eq "A testable entry."
        expect(text_from entry, :content).to fuzzy_match <<~CONTENT
          <h1 id="tiny">Tiny</h1>
          <p>A testable entry.</p>
        CONTENT

        expect { DateTime.parse text_from(entry, :pubDate) }.not_to raise_error
        expect { DateTime.parse text_from(entry, :date) }.not_to raise_error
      end

      it "properly escapes HTML nodes in the article contents" do
        subject

        feed_contents = File.read(
          Dir.glob("#{project.brain.output_directory}/**/my-feed.xml").first
         )

        expect { RSS::Parser.parse feed_contents }.not_to raise_error
      end
    end

    context "when many collections are configured (filename only)" do
      let(:files) {
        {"root-entry.md" => nil, "subdirectory_one/entry.md" => nil}
      }
      let(:config) {
        <<~CONFIG
          rss: default.xml
          subdirectory_one:
            rss: subdirectory-one.xml
        CONFIG
      }

      it "generates more than one RSS feed" do
        pattern = "#{project.brain.output_directory}/**/*.xml"
        expect { subject }
          .to change { Dir.glob(pattern).count }.from(0).to(2)

        # As specified in the custom configuration file.
        #
        expect(Dir.glob(pattern).map { File.basename _1 })
          .to contain_exactly "default.xml", "subdirectory-one.xml"
      end
    end

    context "when a single collection is configured with all options" do
      let(:config) {
        <<~CONFIG
          rss:
            count: 1
            managing_editor: custom@example.com (Custom Editor)
            url: custom.xml
        CONFIG
      }
      let(:files) { {"one.md" => "One", "two.md" => "Two"} }

      it "obeys URL configuration" do
        expect { subject }
          .to change { generated_feed_document("custom.xml") }
          .from(nil)
          .to(instance_of Nokogiri::XML::Document)
      end

      it "obeys count configuration" do
        subject

        feed_items = generated_feed_document.xpath "//item"

        entry_count = files.keys.count

        expect(feed_items.count).not_to eq entry_count
        expect(feed_items.count).to eq 1
      end

      it "obeys managing editor configuration" do
        subject

        managing_editor = generated_feed_document.xpath "//managingEditor"

        expect(managing_editor.text).to eq "custom@example.com (Custom Editor)"
      end
    end
  end

  describe ".name" do
    subject { described_class.name }

    it { is_expected.to eq :rss }
  end

  # Without arguments, this grabs the contents of the first found feed. With a
  # filename argument, it grabs the first feed with the given name.
  #
  # @param filename [String] A feed filename, i.e. "my-feed.xml".
  # @return [Nokogiri::XML::Document, NilClass] Either a document or nil.
  def generated_feed_document(filename = "*.xml")
    document =
      Dir.glob("#{project.brain.output_directory}/**/#{filename}").first
    Nokogiri::XML(File.read document) if document
  end

  def text_from(nokogiri_xml_element, node_name)
    node_name = node_name.to_s == "content" ? "encoded" : node_name

    nokogiri_xml_element
      .children { |child| child.is_a? Nokogiri::XML::Element }
      .detect { |child| child.name == node_name.to_s }
      &.text
  end
end
