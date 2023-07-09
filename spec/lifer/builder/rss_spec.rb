require "spec_helper"

RSpec.describe Lifer::Builder::RSS do
  let(:directory) { temp_root support_file("root_with_entries") }

  before do
    allow(Lifer)
      .to receive(:brain)
      .and_return(Lifer::Brain.init(root: directory))
  end

  describe ".execute" do
    subject { described_class.execute root: directory }

    it "generates a single Atom feed" do
      expect { subject }
        .to change { Dir.glob("#{directory}/_build/**/feed.xml").count }
        .from(0)
        .to(1)
    end

    context "when many collections are configured" do
      let(:config) {
        Lifer::Config.build file: support_file(
          File.join "root_with_entries",
            ".config",
            "custom-config-with-multiple-rss-feeds.yaml"
        )
      }

      it "generates more than one RSS feed" do
        allow(Lifer::Config).to receive(:build).and_return(config)

        pattern = "#{directory}/_build/**/*.xml"
        expect { subject }
          .to change { Dir.glob(pattern).count }.from(0).to(2)

        # As specified in the custom configuration file.
        #
        expect(Dir.glob(pattern).map { File.basename _1 })
          .to contain_exactly "feed.xml", "subdirectory_one.xml"
      end
    end
  end
end

