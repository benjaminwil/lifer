require "spec_helper"
require "lifer/dev/router"
require "lifer/dev/response"

RSpec.describe Lifer::Dev::Router do
  let(:router) { described_class.new(build_directory: "_build") }

  describe "#response_for" do
    subject { router.response_for(request_env) }

    context "for the root document" do
      let(:request_env) { {"PATH_INFO" => ""} }

      it "delegates to the response class for the root index" do
        allow(Lifer::Dev::Response)
          .to receive(:new)
          .with("_build/index.html")
          .and_return(double build: "build called!")

        expect(subject).to eq "build called!"

        expect(Lifer::Dev::Response)
          .to have_received(:new)
          .with("_build/index.html")
          .once
      end
    end

    context "for a named document" do
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

    context "for an index document" do
      let(:request_env) { {"PATH_INFO" => "/collection/"} }

      it "delegates to the response class for the collection index" do
        allow(Lifer::Dev::Response)
          .to receive(:new)
          .with("_build/collection/index.html")
          .and_return(double build: "build called!")

        expect(subject).to eq "build called!"

        expect(Lifer::Dev::Response)
          .to have_received(:new)
          .with("_build/collection/index.html")
          .once
      end
    end
  end
end
