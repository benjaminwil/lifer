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
  let(:config) {
    <<~CONFIG
      rss: feed.xml
      subdirectory_one:
        blah: blah
    CONFIG
  }

  describe ".execute" do
    subject { described_class.execute root: project.brain.root }

    it "generates a single RSS feed" do
      expect { subject }
        .to change {
          Dir.glob("#{project.brain.output_directory}/**/feed.xml").count
        }
        .from(0)
        .to(1)
    end

    it "generates the correct amount of feed items" do
      # We're excluding the entries in `subdirectory_one` here.
      #
      article_count = Dir.glob("#{project.brain.root}/*.md").count

      subject

      generated_feed =
        File.open(
          Dir.glob("#{project.brain.output_directory}/**/feed.xml").first
        ) { Nokogiri::XML _1 }
      feed_items = generated_feed.xpath "//item"

      expect(feed_items.count).to eq article_count
    end

    it "generates parseable article metadata correctly" do
      subject

      generated_feed =
        File.open(
          Dir.glob("#{project.brain.output_directory}/**/feed.xml").first
        ) { Nokogiri::XML _1 }
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

    it "properly escapes HTML nodes in the article contents", :aggregate_failures do
      subject

      feed_contents =
        File.read Dir.glob("#{project.brain.output_directory}/**/feed.xml").first

      expect { RSS::Parser.parse feed_contents }.not_to raise_error
    end

    context "when many collections are configured" do
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
  end

  describe ".name" do
    subject { described_class.name }

    it { is_expected.to eq :rss }
  end

  def text_from(nokogiri_xml_element, node_name)
    node_name = node_name.to_s == "content" ? "encoded" : node_name

    nokogiri_xml_element
      .children { |child| child.is_a? Nokogiri::XML::Element }
      .detect { |child| child.name == node_name.to_s }
      &.text
  end
end
