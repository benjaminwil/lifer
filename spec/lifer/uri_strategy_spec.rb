require "spec_helper"

RSpec.describe Lifer::URIStrategy do
  describe ".name" do
    subject { described_class.name }

    it { is_expected.to eq :uri_strategy }
  end
end
