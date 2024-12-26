require "spec_helper"

RSpec.describe Lifer::Message do
  describe ".error" do
    subject { described_class.error(translation_key, test_mode:) }

    let(:translation_key) { "dev.router.four_oh_four" }

    context "when the translation key is missing" do
      let(:translation_key) { "not.a.real.translation.key" }
      let(:test_mode) { false }

      it "raises an error" do
        expect { subject }.to raise_error(
          I18n::MissingTranslationData,
          "Translation missing: en.not.a.real.translation.key"
        )
      end
    end

    context "when in test mode" do
      let(:test_mode) { true }

      it "does not print to STDOUT" do
        expect { subject }.not_to output("ERR: 404 Not Found").to_stdout
      end
    end

    context "when not in test mode" do
      let(:test_mode) { false }

      it "prints to STDOUT with colour escape codes" do
        expect { subject }
          .to output("\e[31mERR: 404 Not Found\e[0m\n")
          .to_stdout
      end
    end
  end

  describe ".log" do
    subject { described_class.log(translation_key, test_mode:) }

    let(:translation_key) { "dev.router.four_oh_four" }

    context "when the translation key is missing" do
      let(:translation_key) { "not.a.real.translation.key" }
      let(:test_mode) { false }

      it "raises an error" do
        expect { subject }.to raise_error(
          I18n::MissingTranslationData,
          "Translation missing: en.not.a.real.translation.key"
        )
      end
    end

    context "when in test mode" do
      let(:test_mode) { true }

      it "does not print to STDOUT" do
        expect { subject }.not_to output("404 Not Found").to_stdout
      end
    end

    context "when not in test mode" do
      let(:test_mode) { false }

      it "prints to STDOUT" do
        expect { subject }.to output("404 Not Found\n").to_stdout
      end
    end
  end
end
