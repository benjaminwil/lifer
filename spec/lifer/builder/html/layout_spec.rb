require "spec_helper"

RSpec.describe Lifer::Builder::HTML::Layout do
  describe ".build" do
    subject { described_class.build entry: entry }

    let(:collection) {
      Lifer::Collection.generate name: "subdirectory_one",
        directory: "#{spec_lifer.root}/subdirectory_one"
    }
    let(:entry) {
      Lifer::Entry::Markdown.new file: file, collection: collection
    }
    let(:file) { support_file "root_with_entries/tiny_entry.md" }

    context "when not assigning a template file" do
      before do
        spec_lifer!
      end

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
      before do
        spec_lifer! config: <<~CONFIG
          layout_file: ./layouts/layout_with_greeting.html.erb
          uri_strategy: simple
          subdirectory_one:
            uri_strategy: pretty
        CONFIG
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
