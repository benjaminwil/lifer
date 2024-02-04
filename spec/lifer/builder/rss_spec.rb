require "nokogiri"

require "spec_helper"

RSpec.describe Lifer::Builder::RSS do
  before do
    spec_lifer! config_file: "root_with_entries/.config/" \
      "custom-config-with-root-rss-feed.yaml"
  end

  describe ".execute" do
    subject { described_class.execute root: spec_lifer.root }

    it "generates a single RSS feed" do
      expect { subject }
        .to change {
          Dir.glob("#{spec_lifer.output_directory}/**/feed.xml").count
        }
        .from(0)
        .to(1)
    end

    it "generates the correct amount of feed items" do
      # We're excluding the entries in `subdirectory_one` here.
      #
      article_count = Dir.glob("#{spec_lifer.root}/*.md").count

      subject

      generated_feed =
        File.open(
          Dir.glob("#{spec_lifer.output_directory}/**/feed.xml").first
        ) { Nokogiri::XML _1 }
      feed_items = generated_feed.xpath "//item"

      expect(feed_items.count).to eq article_count
    end

    it "generates parseable article metadata correctly" do
      subject

      generated_feed =
        File.open(
          Dir.glob("#{spec_lifer.output_directory}/**/feed.xml").first
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

    it "properly escapes HTML nodes in the article contents" do
      subject

      feed_contents =
        File.read Dir.glob("#{spec_lifer.output_directory}/**/feed.xml").first

      expect(feed_contents).to include "<content:encoded>" \
        "&lt;h1 id=&quot;tiny&quot;&gt;Tiny&lt;/h1&gt;\n\n" \
        "&lt;p&gt;A testable entry.&lt;/p&gt;\n" \
        "</content:encoded>"
    end

    context "when many collections are configured" do
      before do
        spec_lifer! config_file: "root_with_entries/.config/" \
          "custom-config-with-multiple-rss-feeds.yaml"
      end

      it "generates more than one RSS feed" do
        pattern = "#{spec_lifer.output_directory}/**/*.xml"
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
