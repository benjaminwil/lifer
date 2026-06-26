require "spec_helper"

RSpec.describe Lifer::Builder::HTML::FromLiquid do
  describe ".build" do
    subject { described_class.build entry: entry }

    let(:collection) {
      Lifer::Collection.generate name: "subdirectory_one",
        directory: "#{project.root}/subdirectory_one"
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
    let(:project) { Support::LiferTestHelpers::TestProject.new files:, config: }
    let(:files) {
      entry_content_with_variables = File.read(
        File.join Lifer.gem_root,
          "spec/support/entries/layout_variables_test_entry.html.liquid"
      )

      {
        "_layouts/layout.html.liquid" => <<~LIQUID,
          <title>Layout with Greeting</title>
          {% render "_layouts/partial", entry: entry %}
          {{ content }}
        LIQUID
        "_layouts/partial.html.liquid" => <<~LIQUID,
          <header>Header From Partial for "{{ entry.title }}"</header>
        LIQUID
        "subdirectory_one/entry.md" =>
          "This collection must exist for test to pass",
        "entry.html.liquid" => entry_content_with_variables,
        "entry-1.md" => <<~MARKDOWN,
          ---
          title: Entry Title 1
          published: Sun 29 Dec 2024 18:00:19 MST
          authors:
            - One Namesonly
            - Two Namesonly
          tags: tag1, tag2, tag3
          ---
        MARKDOWN
        "entry-2.md" => <<~MARKDOWN
          ---
          title: Entry Title 2
          date: Sun 29 Dec 2024 18:01:25 MST
          updated: Sun 30 Dec 2025 18:00:19 PDT
          authors:
            - name: Nat McCartney
              url: https://example.com
              avatar: https://example.com/haha.png
          tags: tag1
          ---
        MARKDOWN
      }
    }

    context "when using layout-provided variables" do
      let(:config) {
       <<~CONFIG
          layout_file: ../_layouts/layout.html.liquid
          uri_strategy: simple

          subdirectory_one:
            uri_strategy: pretty

          test_setting:
            - number: 123
              description: To tests arrays of objects.
        CONFIG
      }
      let(:entry) {
        Lifer::Entry::HTML.new(
          collection: collection,
          file: "#{project.brain.root}/entry.html.liquid"
        )
      }

      before do
        project.brain.config.register_settings :test_setting
      end

      it "renders a valid HTML document, including rendered layout variables" do
        expect(subject).to fuzzy_match <<~RESULT
          <title>Layout with Greeting</title>
          <header>Header From Partial for "entry"</header>
          <h1>HTML entry with layout variables</h1>
          <h2>Some root collection entry titles</h2>
          <ul>
          <li>
          <span class="title">Entry Title 2</span>
          <span class="published-at">
          Published at &nbsp;
          <time datetime=2024-12-29T18:01:25-07:00>2024-12-29 18:01:25 -0700</time>
          </span>
          <span class="updated-at">
          Updated at &nbsp;
          <time datetime=2025-12-30T18:00:19-07:00>2025-12-30 18:00:19 -0700</time>
          </span>
          <span class="authors">
          Authored by &nbsp;
          <img alt="" src="https://example.com/haha.png"><span class="author">Nat McCartney</span>
          (<a class="url" href="https://example.com">link</a>)
          </li><li>
          <span class="title">Entry Title 1</span>
          <span class="published-at">
          Published at &nbsp;
          <time datetime=2024-12-29T18:00:19-07:00>2024-12-29 18:00:19 -0700</time>
          </span>
          <span class="authors">
          Authored by &nbsp;
          <span class="author">One Namesonly</span>
          <span class="author">Two Namesonly</span>
          </li>
          </ul>
          <h2>All collection names</h2>
          subdirectory_one, root, all_markdown, included_in_feeds
          <h2>All tag names</h2>
          tag1, tag2, tag3
          <h2>Entries for tag1</h2>
          Entry Title 2, Entry Title 1
          <h2>This project's settings</h2>
          all settings: {"layout_file":"../_layouts/layout.html.liquid","uri_strategy":"simple","subdirectory_one":{"uri_strategy":"pretty"},"test_setting":[{"number":123,"description":"To tests arrays of objects."}]}
          root layout file: ../_layouts/layout.html.liquid
          root URI strategy: simple
          subdirectory one URI strategy: pretty
          <h2>Permalinks do not include index.html because of the pretty URI strategy</h2>
          https://example.com/entry
       RESULT
      end
    end

    context "when not assigning a template file" do
      let(:config) { nil }

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

    context "when a layout requests a parent layout" do
      let(:files) {
        {
          "_layouts/parent_layout.html.liquid" => <<~LIQUID,
            <h1>Parent Layout</h1>
            {{ content }}
            {% render "_layouts/parent_layout_footer" %}
          LIQUID
          "_layouts/parent_layout_footer.html.liquid" =>
            "<footer>Footer</footer>",
          "_layouts/child_layout.html.liquid" => <<~LIQUID,
            ---
            layout: _layouts/parent_layout.html.liquid
            ---

            <article class="child">
              {{ content }}
            </article>

            {% render "_layouts/child_layout_footer" %}
          LIQUID
          "_layouts/child_layout_footer.html.liquid" =>
             "<section>Article footer</section>",
          "subdirectory_one/entry.html.liquid" => "Entry content."
        }
      }
      let(:config) {
        <<~CONFIG
          subdirectory_one:
            layout_file: ../_layouts/child_layout.html.liquid
            uri_strategy: pretty
        CONFIG
      }

      it "renders the parent layout enveloping the child layout" do
        expect(subject).to fuzzy_match <<~RESULT
          <h1>Parent Layout</h1>
          <article class="child">
            <h1 id="tiny">Tiny</h1>
            <p>A testable entry.</p>
          </article>
          <section>Article footer</section>
          <footer>Footer</footer>
        RESULT
      end
    end

    context "when referencing a partial that doesn't exist" do
      let(:config) {
        <<~CONFIG
          layout_file: ../_layouts/layout.html.liquid
        CONFIG
      }
      let(:file) {
        temp_file "tiny_entry.md", <<~CONTENT
          ---
          layout: doesnt_exist.html.liquid
          ---
          Some content.
        CONTENT
      }
      let(:files) {
        {
          "_layouts/layout.html.liquid" => <<~LIQUID
            {% render "doesnt_exist" %}
          LIQUID
        }
      }

      it "prints out an error message with context" do
        allow(Lifer::Message).to receive(:error)

        expect { subject }.to raise_error Liquid::FileSystemError

        expect(Lifer::Message).to have_received(:error).with(
          "builder.catchall_failure",
          context: instance_of(String)
        )
      end

      it "bubbles up the standard Ruby error" do
        expect { subject }
          .to raise_error Liquid::FileSystemError, /No such template/
      end
    end
  end
end
