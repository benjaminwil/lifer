RSpec.shared_examples "Lifer::Selection subclass" do
  describe ".generate" do
    subject { described_class.generate }

    it "can be generated" do
      expect(subject).to be_an_instance_of described_class
      expect(subject.name).to eq described_class.name
    end
  end

  describe "#setting" do
    subject { selection.setting :setting_name }

    let(:selection) { described_class.generate }

    it "delegates to the Lifer module" do
      allow(Lifer)
        .to receive(:setting)
        .with(:setting_name, collection: selection, strict: false)

      subject

      expect(Lifer)
        .to have_received(:setting)
        .with(:setting_name, collection: selection, strict: false)
        .once
    end
  end
end
