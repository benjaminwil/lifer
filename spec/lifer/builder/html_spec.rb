require "spec_helper"

RSpec.describe Lifer::Builder::HTML do
  let(:directory) { temp_root(support_file "root_with_entries") }
  let(:contents) { Lifer::Contents.init(directory: directory) }

  describe ".execute" do
    subject { described_class.execute(contents: contents) }

    it "attempts to remove an existing build directory" do
      allow(FileUtils)
        .to receive(:rm_r)
        .with Pathname("#{directory}/_build")

      subject

      expect(FileUtils)
        .to have_received(:rm_r)
        .with Pathname("#{directory}/_build")
    end

    it "generates HTML for each entry" do
      entry_count = Dir.glob("#{directory}/**/*.md").count

      expect { subject }
        .to change { Dir.glob("#{directory}/_build/**/*.html").count }
        .from(0)
        .to(entry_count)
    end
  end
end
