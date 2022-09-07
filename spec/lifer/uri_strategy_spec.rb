require "spec_helper"

RSpec.describe Lifer::URIStrategy do
  describe ".find_by_name" do
    subject { described_class.find_by_name(name) }

    context "when a URI strategy subclass exists" do
      let(:name) { "pretty" }

      it { is_expected.to eq Lifer::URIStrategy::Pretty }
    end

    context "when a URI strategy subclass doesn't exist" do
      let(:name) { "doesnt-exist" }

      it "raises an exception" do
        expect { subject }
          .to raise_error StandardError, "no URI strategy 'doesnt-exist'"
      end
    end
  end
end
