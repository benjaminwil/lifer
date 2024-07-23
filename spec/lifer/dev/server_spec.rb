require "spec_helper"
require "lifer/dev/server"

RSpec.describe Lifer::Dev::Server do
  describe ".start!" do
    subject { described_class.start! }

    it "starts a Puma server" do
      dummy_runner = double(run: "running!")
      allow(Puma::Launcher)
        .to receive(:new)
        .and_return(dummy_runner)

      expect(subject).to eq "running!"

      expect(Puma::Launcher).to have_received(:new).once
      expect(dummy_runner).to have_received(:run).once
    end
  end

  describe ".rack_app" do
    subject { described_class.rack_app }

    it { is_expected.to be_a Proc }
  end
end
