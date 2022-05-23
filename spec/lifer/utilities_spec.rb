require "spec_helper"

RSpec.describe Lifer::Utilities do
  describe ".symbolize_keys" do
    subject { described_class.symbolize_keys(hash) }

    let(:hash) {
      {
        "string": "value",
        symbol: "value",
        sub_hash: {"string": "value"}
      }
    }

    it "symbolizes string keys" do
      expect(subject).to eq(
        {
          string: "value",
          symbol: "value",
          sub_hash: {string: "value"}
        }
      )
    end
  end
end
