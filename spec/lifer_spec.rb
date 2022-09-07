# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lifer do
  it "has a version number" do
    expect(Lifer::VERSION).not_to be nil
  end

  describe ".build!" do
    subject { described_class.build! }

    let(:brain) { instance_double Lifer::Brain }

    context "without an argument" do
      it "calls the builder" do
        allow(Lifer::Brain).to receive(:init).and_return(brain)
        allow(brain).to receive(:build!)

        subject

        expect(brain).to have_received(:build!).once
      end
    end
  end

  describe ".collections" do
    subject { described_class.collections }

    let(:brain) { instance_double Lifer::Brain, collections: [] }

    it "delegates to the brain" do
      allow(Lifer::Brain).to receive(:init).and_return(brain)

      subject

      expect(brain).to have_received(:collections).once
    end
  end

  describe ".ignoreable?" do
    subject { described_class.ignoreable?(file) }

    context "when it matches an ignore directory" do
      let(:file) { "bin/console" }

      it { is_expected.to eq true }
    end

    context "when it matches an ignore pattern" do
      let(:file) { ".config/lifer.yaml" }

      it { is_expected.to eq true }
    end

    context "when it doesn't match an ignore pattern or directory" do
      let(:file) { "posts/my-post.md" }

      it { is_expected.to eq false }
    end
  end

  describe ".manifest" do
    subject { described_class.manifest }

    let(:brain) { instance_double Lifer::Brain, manifest: [] }

    it "delegates to the brain" do
      allow(Lifer::Brain).to receive(:init).and_return(brain)

      subject

      expect(brain).to have_received(:manifest).once
    end
  end

  describe ".output_directory" do
    subject { described_class.output_directory }

    let(:brain) {
      instance_double Lifer::Brain, output_directory: Pathname("haha")
    }

    it "delegates to the brain" do
      allow(Lifer::Brain).to receive(:init).and_return(brain)

      subject

      expect(brain).to have_received(:output_directory).once
    end
  end

  describe ".root" do
    subject { described_class.root }

    let(:brain) { instance_double Lifer::Brain, root: "haha" }

    it "delegates to the brain" do
      allow(Lifer::Brain).to receive(:init).and_return(brain)

      subject

      expect(brain).to have_received(:root).once
    end
  end

  describe ".settings" do
    subject { described_class.settings }

    let(:brain) { instance_double Lifer::Brain }
    let(:config) { instance_double Lifer::Config, settings: {} }

    it "delegates to the brain and config objects" do
      allow(Lifer::Brain).to receive(:init).and_return(brain)
      allow(brain).to receive(:config).and_return(config)

      subject

      expect(brain).to have_received(:config).once
      expect(config).to have_received(:settings).once
    end
  end
end
