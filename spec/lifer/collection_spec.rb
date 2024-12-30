require "spec_helper"

RSpec.describe Lifer::Collection do
  let(:project) { Support::LiferTestHelpers::TestProject.new files:, config: }
  let(:files) {
    {
      "subdirectory_one/entry.html" => nil,
      "subdirectory_one/entry.md" => nil,
      "subdirectory_one/entry2.md" => nil
    }
  }
  let(:config) { "" }

  let(:collection) { described_class.generate(name: "name", directory:) }
  let(:directory) { "#{project.root}/subdirectory_one" }

  describe ".generate" do
    subject { described_class.generate(name: :my_collection, directory:) }

    it "generates a collection" do
      expect(subject.name).to eq :my_collection
    end

    it "immediately generates all entries for the collection" do
      expect(subject.entries).to contain_exactly(
        an_instance_of(Lifer::Entry::HTML),
        an_instance_of(Lifer::Entry::Markdown),
        an_instance_of(Lifer::Entry::Markdown)
      )
    end
  end

  describe "#entries" do
    subject { collection.entries order: }

    let(:files) {
      {
        "old.md" => <<~CONTENT,
          ---
          date: 2020-03-31 00:00:00 -0700
          ---
        CONTENT
        "older.md" => <<~CONTENT,
          ---
          date: 2010-11-31 00:00:00 -0700
          ---
        CONTENT
        "oldest.html" => ""
      }
    }
    let(:collection) {
      described_class.generate name: "name", directory: project.root
    }

    context "when the given order is 'latest'" do
      let(:order) { :latest }

      it "includes entries from a directory in order" do
        expect(File.basename subject.first.file).to eq "old.md"
        expect(File.basename subject.last.file).to eq "oldest.html"
      end
    end

    context "when the given order is 'oldest'" do
      let(:order) { :oldest }

      it "includes entries from a directory in order" do
        expect(File.basename subject.first.file).to eq "oldest.html"
        expect(File.basename subject.last.file).to eq "old.md"
      end
    end
  end

  describe "#layout_file" do
    subject { collection.layout_file }

    context "when the setting is an absolute path" do
      context "containing the gem root" do
        before do
          allow(Lifer).to receive(:gem_root).and_return("/fake/gem_root")
          allow(Lifer)
            .to receive(:setting)
            .with(:layout_file, collection: collection, strict: false)
            .and_return("/fake/gem_root")
        end

        it { is_expected.to eq "/fake/gem_root" }
      end

      context "containing the Lifer root" do
        before do
          allow(Lifer)
            .to receive(:setting)
            .with(:layout_file, collection: collection, strict: false)
            .and_return("#{project.root}/my/layout_file.html.erb")
        end

        it { is_expected.to eq "#{project.root}/my/layout_file.html.erb" }
      end
    end

    context "when the setting is a relative path" do
      before do
        allow(Lifer)
          .to receive(:setting)
          .with(:layout_file, collection: collection, strict: false)
          .and_return("my/layout_file.html.erb")
      end

      it { is_expected.to eq "#{project.root}/.config/my/layout_file.html.erb" }
    end
  end

  describe "#root?" do
    subject { described_class.new(name: name, directory: "whatever").root? }

    context "when the collection is named 'root'" do
      let(:name) { :root }

      it { is_expected.to eq true }
    end

    context "when the collection is not named 'root'" do
      let(:name) { :not_root }

      it { is_expected.to eq false }
    end
  end

  describe "#setting" do
    subject { collection.setting(:setting_name) }

    it "delegates to the global setting method" do
      allow(Lifer)
        .to receive(:setting)
        .with(:setting_name, {collection: collection, strict: false})

      subject

      expect(Lifer)
        .to have_received(:setting)
        .with(:setting_name, {collection: collection, strict: false})
        .once
    end
  end
end
