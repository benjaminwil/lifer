require "spec_helper"
require "lifer/dev/server"

RSpec.describe Lifer::Dev::Server do
  describe ".start!" do
    subject { described_class.start! port: 9292 }

    it "starts a Puma server" do
      dummy_runner = double(run: "running!")
      dummy_listener = double(start: true)
      allow(Puma::Launcher).to receive(:new).and_return(dummy_runner)
      allow(Listen).to receive(:to).and_return(dummy_listener)
      allow(Lifer).to receive(:build!)

      expect(subject).to eq "running!"

      expect(Lifer).to have_received(:build!).once
      expect(Listen).to have_received(:to).with(instance_of String).once
      expect(Puma::Launcher).to have_received(:new).once
      expect(dummy_runner).to have_received(:run).once
    end
  end

  describe ".rack_app" do
    subject { described_class.rack_app }

    it { is_expected.to be_a Proc }
  end
end
