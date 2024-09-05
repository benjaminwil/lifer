require "spec_helper"

RSpec.describe Lifer::Utilities do
  let(:described_module) { described_class }

  describe ".bold_text" do
    subject { described_module.bold_text "string" }

    it { is_expected.to eq "\e[1mstring\e[0m" }
  end

  describe ".classify" do
    subject { described_module.classify string }

    context "when the given string matches an existing constant" do
      let(:string) { "lifer/entry/markdown" }

      it { is_expected.to eq Lifer::Entry::Markdown }
    end

    context "when the given string does not match a constant" do
      let(:string) { "lifer/selection/doesnt_exist" }

      it "raises a helpful error" do
        expect { subject }.to raise_error RuntimeError,
          "could not find constant for path " \
            "\"lifer/selection/doesnt_exist\" " \
            "(Lifer::Selection::DoesntExist)\n"
      end
    end
  end

  describe ".file_extension" do
    subject { described_module.file_extension path }

    context "when there is no extension" do
      let(:path) { Pathname "no/extension" }

      it { is_expected.to eq "" }
    end

    context "when the extension is simple" do
      let(:path) { Pathname "a-normal/extension.html" }

      it { is_expected.to eq ".html" }
    end

    context "when the extension is complex" do
      let(:path) { Pathname "my-cool-website.com/r/extension.html.erb.haha" }

      it { is_expected.to eq ".html.erb.haha" }
    end
  end

  describe ".symbolize_keys" do
    subject { described_class.symbolize_keys(hash) }

    let(:hash) {
      {
        "string": "value",
        symbol: "value",
        sub_hash: {"string": "value"}
      }
    }

    it "symbolizes string keys" do
      expect(subject).to eq(
        {
          string: "value",
          symbol: "value",
          sub_hash: {string: "value"}
        }
      )
    end
  end
end
