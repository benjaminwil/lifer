require "spec_helper"

RSpec.describe Lifer::Builder do
  describe ".find" do
    subject { described_class.find name }

    context "when a builder with the given name exists" do
      let(:name) { :html }

      it { is_expected.to eq Lifer::Builder::HTML }
    end

    context "when a builder with the given name does not exist" do
      let(:name) { :doesntexist }

      it "raises an error" do
        expect { subject }
          .to raise_error StandardError, "no builder with name \"doesntexist\""
      end
    end
  end

  describe ".name" do
    subject { described_class.name }

    it { is_expected.to eq :builder }
  end
end
