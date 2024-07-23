require "spec_helper"

require "lifer/dev/response"

RSpec.describe Lifer::Dev::Response do
  let(:response) { described_class.new path }

  describe "#build" do
    subject { response.build }

    context "with a supported file type and a file that exists" do
      let(:path) { temp_file("real-html-file.html", "contents") }

      it "returns a 200 response" do
        expect(subject)
          .to eq [200, {"Content-Type": "text/html"}, ["contents\n"]]
      end
    end

    context "with a supported file type and a file that does not exist" do
      let(:path) { "html-file.html" }

      it "returns a 404 response" do
        expect(subject)
          .to eq [404, {"Content-Type": "text/html"}, ["404 Not Found"]]
      end
    end

    context "with an unsupported file type" do
      let(:path) { temp_file("unsupported-file-type.zzz") }

      it "raises an error" do
        expect { subject }.to raise_error(NotImplementedError)
      end
    end
  end
end
