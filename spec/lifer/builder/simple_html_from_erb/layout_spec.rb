require "spec_helper"

RSpec.describe Lifer::Builder::SimpleHTMLFromERB::Layout do
  describe ".build" do
    subject { described_class.build entry: entry }

    let(:collection) {
      Lifer::Collection.generate name: "Collection",
        directory: File.dirname(file)
    }
    let(:entry) {
      Lifer::Entry::Markdown.new file: file, collection: collection
    }
    let(:file) { support_file "root_with_entries/tiny_entry.md" }

    context "when not assigning a template file" do
      it "renders a valid HTML document using the default template" do
        expect(subject).to fuzzy_match <<~RESULT
          <html>
            <head>
            </head>
            <body>
              <h1 id="tiny">Tiny</h1>
              <p>A testable entry.</p>
            </body>
          </html>
        RESULT
      end
    end

    context "when the collection has its own layout file" do
      let(:config) {
        Lifer::Config.build(
          file: support_file(
            "root_with_entries/.config/custom-root-layout-lifer.yaml"
          )
        )
      }

      before do
        allow(Lifer::Config).to receive(:build).and_return(config)
      end

      it "renders a valid HTML document using any other template" do
        expect(subject).to fuzzy_match <<~RESULT
          <html>
            <head>
              <title>Layout with Greeting</title>
            </head>
            <body>
              <header>
                Greetings! Have this beverage!
              </header>
              <article>
                <h1 id="tiny">Tiny</h1>
                <p>A testable entry.</p>
              </article>
            </body>
          </html>
        RESULT
      end
    end
  end
end
