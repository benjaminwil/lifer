require "spec_helper"

RSpec.describe Lifer::Config do
  let(:config) { described_class.build(file: file) }

  describe "#file" do
    subject { config.file }

    context "when given a non-existent file" do
      let(:file) { "../haha" }

      it "notifies the user there's no configuration file being loaded" do
        expect { subject }
          .to output(/^No configuration file at/)
          .to_stdout
      end
    end

    context "when given an existing file" do
      let(:file) { support_file "root_with_entries/.config/lifer.yaml" }

      it "doesn't load the default configuration file" do
        expect { subject }
          .not_to output(/^No configuration file at/)
          .to_stdout
      end

      it "uses the given config file" do
        expect(subject).to be_a Pathname
        expect(subject.to_s).to end_with "root_with_entries/.config/lifer.yaml"
      end
    end
  end

  describe "#settings" do
    subject { config.settings }

    let(:file) { support_file "root_with_entries/.config/lifer.yaml" }

    it "loads some YAML" do
      expect(subject).to eq(
        {
          subdirectory_one: {uri_strategy: "pretty"},
          uri_strategy: "simple"
        }
      )
    end
  end
end
