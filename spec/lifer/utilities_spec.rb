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

  describe ".date_as_iso8601" do
    subject { described_module.date_as_iso8601 datetime }

    let(:datetime) { "1990-01-01" }

    it { is_expected.to eq "1990-01-01T00:00:00+00:00" }
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

  describe ".handleize" do
    subject {
      described_class.handleize(
        "Hello 111. complex_string with ?? --- 'many' things in it"
      )
    }

    it { is_expected.to eq "hello-111-complex_string-with-many-things-in-it" }
  end

  describe ".parallelized" do
    subject {
      described_class.parallelized collection do |x|
        x * 2
      end
    }

    context "by default (parallelism enabled)" do
      context "when no errors should be raised" do
        let(:collection) { [1, 2, 3] }

        it { is_expected.to eq [2, 4, 6] }
      end

      context "when an error should be raised" do
        let(:collection) { [1, 2, nil, 3] }

        it "bubbles up the exception" do
          expect { subject }.to raise_error NoMethodError, /for nil/
        end
      end
    end

    context "when parallelism is disabled" do
      around do |example|
        original_value = ENV["LIFER_UNPARALLELIZED"]
        ENV["LIFER_UNPARALLELIZED"] = "truthy"
        example.run
      ensure
        ENV["LIFER_UNPARALLELIZED"] = original_value
      end

      context "when no errors should be raised" do
        let(:collection) { [1, 2, 3] }

        it { is_expected.to eq [2, 4, 6] }
      end

      context "when an error should be raised" do
        let(:collection) { [1, 2, nil, 3] }

        it "bubbles up the exception" do
          expect { subject }.to raise_error NoMethodError, /for nil/
        end
      end
    end
  end

  describe ".stringify_keys" do
    subject { described_class.stringify_keys(hash) }

    context "when the given hash is actually nil" do
      let(:hash) { nil }

      it { is_expected.to eq({}) }
    end

    context "when the given hash is empty" do
      let(:hash) { {} }

      it { is_expected.to eq({}) }
    end

    context "when the given hash contains data" do
      let(:hash) {
        {
          "string": "value",
          symbol: "value",
          sub_hash: {"string": "value", symbol: :value}
        }
      }

      it "stringifies keys" do
        expect(subject).to eq(
          {
            "string" => "value",
            "symbol" => "value",
            "sub_hash" => {
              "string" => "value",
              "symbol" => :value
            }
          }
        )
      end
    end
  end

  describe ".symbolize_keys" do
    subject { described_class.symbolize_keys(hash) }

    context "when the given hash is actually nil" do
      let(:hash) { nil }

      it { is_expected.to eq({}) }
    end

    context "when the given hash is empty" do
      let(:hash) { {} }

      it { is_expected.to eq({}) }
    end

    context "when the given hash contains data" do
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
end
