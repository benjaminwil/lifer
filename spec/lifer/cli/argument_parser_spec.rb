require "spec_helper"
require "lifer/cli/argument_parser"

RSpec.describe Lifer::CLI::ArgumentParser do
  let(:parser) { described_class.new(input: input, subcommands: subcommands) }

  describe "#output" do
    subject { parser.output }

    context "without a subcommand" do
      let(:input) {
        [
          "--config='with-equals'",
          "--root",
          "without-equals",
          "-h",
          "-s",
          "short-with-argument",
          "-v",
          "--no-value",
          "--pretty",
          "--duplicate",
          "--duplicate",
          "--an-array",
          "1,2,3,4",
          "--another=with-equals"
        ]
      }
      let(:subcommands) { [] }

      it "provides parsed commandline arguments" do
        expect(subject).to eq :config => "with-equals",
          :root => "without-equals",
          :h => true,
          :s => "short-with-argument",
          :v => true,
          :"no-value" => true,
          :pretty => true,
          :duplicate => true,
          :"an-array" => ["1", "2", "3", "4"],
          :another => "with-equals"
      end
    end

    context "without a valid subcommand" do
      let(:input) { ["non-valid-subcommand", "--verbose"] }
      let(:subcommands) { [:serve] }

      it "does nothing with the invalid subcommand" do
        expect(subject).to eq verbose: true
      end
    end

    context "with a valid subcommand" do
      let(:input) { ["valid-subcommand", "--verbose"] }
      let(:subcommands) { [:"valid-subcommand"] }

      it "does not treat the subcommand as a regular argument" do
        expect(subject).to eq verbose: true
      end
    end
  end

  describe "#subcommand" do
    subject { parser.subcommand }

    let(:subcommands) { ["serve"] }

    context "when no subcommand is given" do
      let(:input) { [] }

      it { is_expected.to be_nil }
    end

    context "when an invalid subcommand is given" do
      let(:input) { ["not-valid"] }

      it { is_expected.to be_nil }
    end

    context "when a valid subcommand is given" do
      let(:input) { ["serve"] }

      it { is_expected.to eq :serve }
    end
  end
end
