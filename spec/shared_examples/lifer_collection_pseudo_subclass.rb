RSpec.shared_examples "Lifer::Collection::Pseudo subclass" do
  describe ".generate" do
    subject { described_class.generate }

    it "can be generated" do
      expect(subject).to be_an_instance_of described_class
      expect(subject.name).to eq described_class.name
    end
  end

  describe "#setting" do
    subject { pseudo_collection.setting :setting_name }

    let(:pseudo_collection) { described_class.generate }

    it "delegates to the Lifer module" do
      allow(Lifer)
        .to receive(:setting)
        .with(:setting_name, collection: pseudo_collection, strict: false)

      subject

      expect(Lifer)
        .to have_received(:setting)
        .with(:setting_name, collection: pseudo_collection, strict: false)
        .once
    end
  end
end
