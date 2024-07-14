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


    context "when using layout-provided variables" do
      let(:entry) {
        Lifer::Entry::HTML.new collection: collection,
          file: support_file(
            "root_with_entries/html_entry_with_layout_variables.html.erb"
          )
      }

      before do
        spec_lifer!
      end

      it "renders a valid HTML document, including rendered layout variables" do
        expect(subject).to fuzzy_match <<~RESULT
          <html>
           <head>
           </head>
           <body>
             <h1>HTML entry with layout variables</h1>
             <h2>Some root collection entry titles</h2>
             Untitled Entry, Untitled Entry
             <h2>All collection names</h2>
             subdirectory_one, root, all_markdown, included_in_feeds
             <h2>This project's settings</h2>
             {:uri_strategy=>"simple", :subdirectory_one=>{:uri_strategy=>"pretty"}}
           </body>
         </html>
       RESULT
      end
    end

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
