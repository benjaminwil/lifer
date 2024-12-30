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
      "_layouts/layout.html.erb" => "Layout was loaded!\n\n<%= content %>",
      "entry-with-variables.html.erb" => entry_content_with_variables,
      "another-entry.md" => "---\ntitle: Another Entry\n---\n",
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
             entry-with-variables, Another Entry
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
