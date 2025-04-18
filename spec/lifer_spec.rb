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

        expect(brain).to have_received(:build!).with(environment: :build).once
      end
    end
  end

  describe ".collections" do
    subject {
      described_class.collections(without_selections: without_selections)
    }

    before do
      Support::LiferTestHelpers::TestProject.new
    end

    context "by default" do
      let(:without_selections) { false }

      it "returns all collections and selections", :aggregate_failures do
        expect(subject).to include instance_of(Lifer::Collection)

        expect(subject.map(&:class).map(&:superclass))
          .to include(Lifer::Selection)
      end
    end

    context "when excluding selections" do
      let(:without_selections) { true }

      it "returns only `Lifer::Collection`s" do
        expect(subject.map(&:class).uniq).to contain_exactly Lifer::Collection
      end
    end
  end

  describe ".config_file" do
    subject { described_class.config_file }

    let(:brain) { instance_double Lifer::Brain }
    let(:config) { instance_double Lifer::Config }

    it "delegates to the config object" do
      allow(Lifer::Brain).to receive(:init).and_return(brain)
      allow(brain).to receive(:config).and_return(config)
      allow(config).to receive(:file).once

      subject

      expect(config).to have_received(:file).once
    end
  end

  describe ".entry_manifest" do
    subject { described_class.entry_manifest }

    let(:brain) { instance_double Lifer::Brain, entry_manifest: [] }

    it "delegates to the brain" do
      allow(Lifer::Brain).to receive(:init).and_return(brain)

      subject

      expect(brain).to have_received(:entry_manifest).once
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

  describe ".parallelism_disabled?" do
    subject { described_class.parallelism_disabled? }

    context "by default" do
      it { is_expected.to eq false }
    end

    context "when parallelism has been disabled by the user" do
      it "returns true" do
        original_value = ENV["LIFER_UNPARALLELIZED"]
        ENV["LIFER_UNPARALLELIZED"] = "truthy"

        expect(subject).to eq true
      ensure
        ENV["LIFER_UNPARALLELIZED"] = original_value
      end
    end
  end

  describe ".register_settings" do
    subject { described_class.register_settings *settings }

    let(:brain) { instance_double Lifer::Brain, root: "haha" }
    let(:config) { instance_double Lifer::Config }
    let(:settings) { [something: [:something_else]] }

    it "delegates to the config object" do
      allow(Lifer::Brain).to receive(:init).and_return(brain)
      allow(brain).to receive(:config).and_return(config)
      allow(config)
        .to receive(:register_settings)
        .with({something: [:something_else]})
        .and_return(true)

      subject

      expect(config)
        .to have_received(:register_settings)
        .with({something: [:something_else]})
        .once
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

  describe ".setting" do
    subject { described_class.setting :some_argument }

    let(:brain) { instance_double Lifer::Brain }

    it "delegates to the brain" do
      allow(Lifer::Brain).to receive(:init).and_return(brain)
      allow(brain)
        .to receive(:setting)
        .with(:some_argument, {collection: nil, strict: false})

      subject

      expect(brain)
        .to have_received(:setting)
        .with(:some_argument, {collection: nil, strict: false})
        .once
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

  describe ".tag_manifest" do
    subject { described_class.tag_manifest }

    let(:brain) { instance_double Lifer::Brain, tag_manifest: [] }

    it "delegates to the brain" do
      allow(Lifer::Brain).to receive(:init).and_return(brain)

      subject

      expect(brain).to have_received(:tag_manifest).once
    end
  end
end
