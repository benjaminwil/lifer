require "spec_helper"

require "lifer/cli"

RSpec.describe Lifer::CLI do
  describe ".start!" do
    subject { described_class.start! }

    it "delegates to an instance" do
      dummy_cli = instance_double described_class, start!: true
      allow(described_class).to receive(:new).and_return(dummy_cli)

      subject

      expect(dummy_cli).to have_received(:start!).once
    end
  end

  describe "#start!" do
    subject { cli.start! }

    let(:cli) { described_class.new }

    # FIXME: Because we mock `OptionParser`, this test can fail when being run
    # in parallel. I think the solution is to mock in some other way, or stop
    # mocking.
    #
    it "parses arguments and builds the Lifer project" do
      dummy_option_parser = instance_double OptionParser, parse!: true

      allow(OptionParser).to receive(:new).and_return(dummy_option_parser)
      allow(Lifer).to receive(:build!)

      subject

      expect(dummy_option_parser)
        .to have_received(:parse!)
        .with(anything)
        .at_least(:once)
      expect(Lifer).to have_received(:build!).once
    end
  end
end
