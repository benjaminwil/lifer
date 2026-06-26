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
      "_layouts/partials/header.html.erb" => <<~TEXT,
        <header id="<%= id %>">
          This project contains <%= collections.count %> collections
        </header>
      TEXT
      "_layouts/partials/icon.html.erb" => <<~TEXT,
        <span class="icon"><%= icon_name %></span>
      TEXT
      "_layouts/root.html.erb" => <<~TEXT,
        <html>
          <body>
            <%= render "_layouts/partials/header.html.erb", id: "header-123" %>
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
      "entry-with-render.html.erb" => <<~TEXT,
        ---
        title: Entry With Render
        ---

        <p>Before icon</p>
        <%= render "_layouts/partials/icon.html.erb", icon_name: "star" %>
        <p>After icon</p>
      TEXT
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

    context "when an entry template calls render" do
      let(:entry) {
        Lifer::Entry::HTML.new collection: collection,
          file: "#{project.root}/entry-with-render.html.erb"
      }
      let(:config) {
        <<~CONFIG
          layout_file: ../_layouts/layout.html.erb
          uri_strategy: simple
          subdirectory_one:
            uri_strategy: pretty
        CONFIG
      }

      it "renders the partial within the entry content" do
        expect(subject).to include '<span class="icon">star</span>'
      end
    end

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
             Untitled Entry (published: 1900-01-01 00:00:00 +0000, updated: )
             entry-with-variables (published: 1900-01-01 00:00:00 +0000, updated: )
             Entry With Render (published: 1900-01-01 00:00:00 +0000, updated: )
             Another Entry (published: 1900-01-01 00:00:00 +0000, updated: )
             Another Another Entry (published: 1900-01-01 00:00:00 +0000, updated: 2000-01-01 00:00:01 +0000)
             <h2>All collection names</h2>
             subdirectory_one, root, all_markdown, included_in_feeds
             <h2>All tag names</h2>
             tag1, tag2, tag3
             <h2>Entries for tag1</h2>
             Another Entry, Another Another Entry
             <h2>This project's settings</h2>
             {"uri_strategy":"simple","subdirectory_one":{"uri_strategy":"pretty"}}
             <h2>Entry permalinks do not include index.html because of the pretty URI strategy</h2>
             https://example.com/entry-with-variables
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
              <header id="header-123">
                This project contains 3 collections
              </header>
              <main><p>Another entry</p>
              </main>
            </body>
          </html>
        RESULT
      end
    end

    context "when a layout file references another layout file that doesn't exist" do
      before do
        files["_layouts/layout.html.erb"] = "<%= render 'doesnt_exist.html.erb' %>"
      end

      let(:entry) {
        Lifer::Entry::HTML.new collection: collection,
          file: "#{project.root}/entry-with-render.html.erb"
      }
      let(:config) {
        <<~CONFIG
          layout_file: ../_layouts/layout.html.erb
          uri_strategy: simple
          subdirectory_one:
            uri_strategy: pretty
        CONFIG
      }

      it "prints out an error message with context" do
        allow(Lifer::Message).to receive(:error)

        expect { subject }.to raise_error Errno::ENOENT

        expect(Lifer::Message).to have_received(:error).with(
          "builder.catchall_failure",
          context: instance_of(String)
        )
      end

      it "bubbles up the standard Ruby error" do
        expect { subject }
          .to raise_error Errno::ENOENT, /No such file or directory @ rb_sysopen/
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
