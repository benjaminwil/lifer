# frozen_string_literal: true

RSpec.describe Lifer do
  it "has a version number" do
    expect(Lifer::VERSION).not_to be nil
  end

  describe ".build" do
    subject { described_class.build }

    context "without an argument" do
      it "calls the builder" do
        allow(Lifer::Builder::HTML)
          .to receive(:execute)
          .with(root: Dir.pwd)

        subject

        expect(Lifer::Builder::HTML)
          .to have_received(:execute)
          .with(root: Dir.pwd)
      end
    end

    context "with an argument" do
      subject { described_class.build(directory: directory) }

      let(:directory) { temp_root(support_file "root_with_entries") }
      let(:contents)  { instance_double Lifer::Contents }

      it "calls the builder" do
        allow(Lifer::Builder::HTML).to receive(:execute)

        subject

        expect(Lifer::Builder::HTML).to have_received(:execute)
      end
    end
  end

  describe ".collections" do
    subject { described_class.collections }

    let(:directory) { support_file "root_with_entries" }

    before do
      use_support_config "root_with_entries/.config/lifer.yaml"

      Lifer.class_variable_set("@@root", directory)
    end

    it "creates collections as described in the .config/lifer.yaml" do
      expect(subject).to contain_exactly(
        an_instance_of(Lifer::Collection),
        an_instance_of(Lifer::Collection)
      )
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

    context "when fresh" do
      it { is_expected.to be_an_instance_of Set }
    end

    context "after a build" do
      before do
        Lifer.build(directory: directory)
      end

      let(:directory) { temp_root(support_file "root_with_entries") }
      let(:directory_entry_count) {
        Dir
          .glob("#{directory}/**/*.md")
          .select { |entry| File.file? entry }
          .count
      }

      it "lists all entries" do
        expect(subject).to be_an_instance_of Set
        expect(subject.count).to eq directory_entry_count
      end
    end
  end
end
