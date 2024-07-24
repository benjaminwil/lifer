require "spec_helper"
require "lifer/cli"

RSpec.describe Lifer::CLI::ArgumentExecutor do
  describe "#execute!" do
    subject { described_class.execute! args: args }

    context "when given the --help argument after another argument" do
      it "displays help text and exits",
        pending: "There are no arguments other than help yet..." do
        subject
      end
    end

    context "when given the --help argument" do
      let(:args) { {help: true} }

      it "displays help text and exits" do
        allow(Lifer::CLI).to receive(:exit!).and_return("Exit process")



        expect { subject }.to output(/Lifer, the static site generator/).to_stdout

        expect(Lifer::CLI).to have_received(:exit!).once
      end
    end

    context "when given unregistered arguments" do
      let(:args) { {unregistered: "setting"} }

      it "does nothing" do
        executor_double =
          instance_double Lifer::CLI::ArgumentExecutor, public_send: "public_send"
        allow(Lifer::CLI::ArgumentExecutor)
          .to receive(:new)
          .and_return(executor_double)

        subject

        expect(executor_double).not_to have_received(:public_send)
      end
    end
  end
end
