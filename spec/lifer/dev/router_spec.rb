require "spec_helper"
require "lifer/dev/router"
require "lifer/dev/response"

RSpec.describe Lifer::Dev::Router do
  let(:router) { described_class.new(build_directory: "_build") }

  describe "#response_for" do
    subject { router.response_for(request_env) }

    let(:request_env) { {"PATH_INFO" => "/page.html"} }

    it "delegates to the response class" do
      allow(Lifer::Dev::Response)
        .to receive(:new)
        .with("_build/page.html")
        .and_return(double build: "build called!")

      expect(subject).to eq "build called!"

      expect(Lifer::Dev::Response)
        .to have_received(:new)
        .with("_build/page.html")
        .once
    end
  end
end
