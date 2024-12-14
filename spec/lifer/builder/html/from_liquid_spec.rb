require "spec_helper"

RSpec.describe Lifer::Builder::HTML::FromLiquid do
  describe ".build" do
    subject { described_class.build entry: entry }

    let(:collection) {
      Lifer::Collection.generate name: "subdirectory_one",
        directory: "#{spec_lifer.root}/subdirectory_one"
    }
    let(:entry) {
      Lifer::Entry::Markdown.new file: file, collection: collection
    }
    let(:file) {
      temp_file "tiny_entry.md", <<~CONTENT
        # Tiny

        A testable entry.
      CONTENT
    }

    context "when using layout-provided variables" do
      let(:entry) {
        Lifer::Entry::HTML.new collection: collection,
          file: support_file(
            "root_with_entries/html_liquid_entry_with_layout_variables.html.liquid"
          )
      }

      before do
        spec_lifer! config: <<~CONFIG
          layout_file: ./layouts/layout_with_greeting.html.liquid
          uri_strategy: pretty

          subdirectory_one:
            uri_strategy: simple

          test_setting:
            - number: 123
              description: To tests arrays of objects.
        CONFIG

        spec_lifer.config.register_settings :test_setting
      end

      it "renders a valid HTML document, including rendered layout variables" do
        expect(subject).to fuzzy_match <<~RESULT
          <html>
           <head>
             <title>Layout with Greeting</title>
           </head>
           <body>
             <header>
               Header From Partial for "html_liquid_entry_with_layout_variables"
             </header>
             <article>
               <h1>HTML entry with layout variables</h1>
               <h2>Some root collection entry titles</h2>
               Untitled Entry, Untitled Entry
               <h2>All collection names</h2>
               subdirectory_one, root, all_markdown, included_in_feeds
               <h2>This project's settings</h2>
               all settings: {"layout_file":"./layouts/layout_with_greeting.html.liquid","uri_strategy":"pretty","subdirectory_one":{"uri_strategy":"simple"},"test_setting":[{"number":123,"description":"To tests arrays of objects."}]}
               root layout file: ./layouts/layout_with_greeting.html.liquid
               root URI strategy: pretty
               subdirectory one URI strategy: simple
             </article>
           </body>
         </html>
       RESULT
      end
    end

    context "when not assigning a template file" do
      it "does not render properly, because the default template is ERB" do
        expect(subject).to fuzzy_match <<~RESULT
          <html>
            <head>
            </head>
            <body>
              <%= content %>
            </body>
          </html>
        RESULT
      end
    end

    context "when the collection has its own layout file" do
      before do
        spec_lifer! config: <<~CONFIG
          layout_file: ./layouts/layout_with_greeting.html.liquid
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
                Header From Partial for "Untitled Entry"
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

    context "when a layout requests a parent layout" do
      before do
        spec_lifer! config: <<~CONFIG
          layout_file: ../_layouts/child_layout.html.liquid
          subdirectory_one:
            uri_strategy: pretty
        CONFIG
      end

      it "renders the parent layout enveloping the child layout" do
        expect(subject).to fuzzy_match <<~RESULT
          <html>
            <head>
              <title> Parent Layout. Full HTML document. </title>
            </head>

            <body>
              <article class="child">
                <h1> Child of Parent Layout. Not a complete HTML document. </h1>
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
