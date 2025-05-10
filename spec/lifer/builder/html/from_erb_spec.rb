require "spec_helper"

RSpec.describe Lifer::Builder::HTML::FromERB do
  let(:project) {
    Support::LiferTestHelpers::TestProject.new files:, config:
  }
  let(:config) {
    <<~CONFIG
      uri_strategy: simple
      subdirectory_one:
        uri_strategy: pretty
    CONFIG
  }
  let(:files) {
    entry_content_with_variables = File.read(
      File.join Lifer.gem_root,
        "spec/support/entries/layout_variables_test_entry.html.erb"
    )

    {
      "_layouts/root.html.erb" => <<~TEXT,
        <html>
          <body>
            <%= content %>
          </body>
        </html>
      TEXT
      "_layouts/layout.html.erb" => "Layout was loaded!\n\n<%= content %>",
      "_layouts/layout_referencing_root.html.erb" => <<~TEXT,
        ---
        layout: _layouts/root.html.erb
        ---
        <main><%= content %></main>
      TEXT
      "entry-with-variables.html.erb" => entry_content_with_variables,
      "another-entry.md" => <<~TEXT,
        ---
        title: Another Entry
        tags: tag1, tag2, tag3
        ---

        Another entry
      TEXT
      "another-another-entry.md" => <<~TEXT,
        ---
        title: Another Another Entry
        tags: tag1
        updated_at: 2000-01-01 00:00:01 +0000
        ---
      TEXT
      "subdirectory_one/tiny_entry.md" => "Entry content."
    }
  }
  let(:entry) {
    Lifer::Entry::Markdown.new(
      file: "#{project.root}/subdirectory_one/tiny_entry.md",
      collection: collection
    )
  }

  describe ".build" do
    subject { described_class.build entry: entry }

    let(:collection) {
      Lifer::Collection.generate name: "subdirectory_one",
        directory: "#{project.root}/subdirectory_one"
    }

    context "when using layout-provided variables" do
      let(:entry) {
        Lifer::Entry::HTML.new collection: collection,
          file: "#{project.root}/entry-with-variables.html.erb"
      }

      it "renders a valid HTML document, including rendered layout variables" do
        expect(subject).to fuzzy_match <<~RESULT
          <html>
           <head>
           </head>
           <body>
             <h1>HTML entry with layout variables</h1>
             <h2>Some root collection entry titles</h2>
             entry-with-variables (published: 1900-01-01 00:00:00 +0000, updated: )
             Another Entry (published: 1900-01-01 00:00:00 +0000, updated: )
             Another Another Entry (published: 1900-01-01 00:00:00 +0000, updated: 2000-01-01 00:00:01 +0000)
             <h2>All collection names</h2>
             subdirectory_one, root, all_markdown, included_in_feeds
             <h2>All tag names</h2>
             tag1, tag2, tag3
             <h2>Entries for tag1</h2>
             Another Another Entry, Another Entry
             <h2>This project's settings</h2>
             {:uri_strategy=>"simple", :subdirectory_one=>{:uri_strategy=>"pretty"}}
           </body>
         </html>
       RESULT
      end
    end

    context "when referencing a root layout in the frontmatter" do
      let(:config) {
        <<~CONFIG
          layout_file: ../_layouts/layout_referencing_root.html.erb
        CONFIG
      }
      let(:entry) {
        Lifer::Entry::Markdown.new(
          file: "#{project.root}/another-entry.md",
          collection: collection
        )
      }

      it "renders the document with the root and collection layouts" do
        expect(subject).to fuzzy_match <<~RESULT
          <html>
            <body>
              <main><p>Another entry</p>
              </main>
            </body>
          </html>
        RESULT
      end
    end

    context "when not assigning a template file" do
      it "renders a valid HTML document using the default template" do
        expect(subject).to fuzzy_match <<~RESULT
          <html>
            <head>
            </head>
            <body>
              <p>Entry content.</p>
            </body>
          </html>
        RESULT
      end
    end

    context "when the collection has its own layout file" do
      let(:config) {
        <<~CONFIG
          layout_file: ../_layouts/layout.html.erb
          uri_strategy: simple
          subdirectory_one:
            uri_strategy: pretty
        CONFIG
      }

      it "renders a valid HTML document using any other template" do
        expect(subject).to fuzzy_match <<~RESULT
          Layout was loaded!
          <p>Entry content.</p>
        RESULT
      end
    end
  end
end
