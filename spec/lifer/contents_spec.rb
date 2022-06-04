require "spec_helper"

RSpec.describe Lifer::Contents do
  let(:contents) { described_class.init(directory: directory) }

  before do
    use_support_config "root_with_entries/.config/lifer.yaml"
  end

  describe "#collections" do
    subject { contents.collections }

    let(:directory) { support_file "root_with_entries" }

    it "creates collections as described in the .config/lifer.yaml" do
      expect(subject.map(&:name)).to eq [:subdirectory_one, :root]
    end
  end
end
