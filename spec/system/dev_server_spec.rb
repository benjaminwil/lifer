require "capybara/rspec"

require "spec_helper"
require "lifer/dev/server"

Capybara.app = Lifer::Dev::Server.rack_app
Capybara.server = :puma, {Silent: true}

RSpec.feature "dev server", type: :system do
  def build_with(files:, config: nil)
    args = {files:, config:}.reject { _2.nil? }
    Support::LiferTestHelpers::TestProject.new(**args)
    Lifer.build!
  end

  scenario "serving HTML entries" do
    build_with files: {
      "markdown-entry.md" => "Simple Markdown entry",
      "html-entry.html" => "Simple HTML entry",
      "erb-entry.html.erb" => "Entry with ERB: <%= 2 + 2 %>"
    }

    visit "/markdown-entry.html"
    expect(page).to have_text "Simple Markdown entry"

    visit "/html-entry.html"
    expect(page).to have_text "Simple HTML entry"

    visit "/erb-entry.html"
    expect(page).to have_text "Entry with ERB: 4"
  end

  scenario "serving only servable project pages" do
    build_with files: {"entry.html" => "A testable entry"}

    visit "/not-a-page.html"
    expect(page).to have_text "404 Not Found"

    expect do
      visit "/not-a-valid-file-type.zzz"
    end.to raise_error NotImplementedError

    visit "/entry.html"
    expect(page).to have_text "A testable entry"
  end

  scenario "serving plain text files" do
    build_with files: {"text.txt" => "Text sans layout garbage"}

    visit "/text.html"
    expect(page).to have_text "404 Not Found"

    visit "/text.txt"
    expect(page).to have_text "Text sans layout garbage"
    expect(page).not_to have_content "<html>"
    expect(page).not_to have_content "<body>"
  end

  scenario "serving Liquid layouts with nested partials" do
    files = {
      "_layouts/layout.html.liquid" => <<~LIQUID,
        {% render "_layouts/parent_partial" with entry: entry %}
        <main>{{ content }}</main>
      LIQUID
      "_layouts/parent_partial.html.liquid" => <<~LIQUID,
        <p>Parent partial content</p>
        <p>Date: {{ entry.published_at | date_to_xmlschema }}
        {% render "_layouts/child_partial" with entry: entry %}
      LIQUID
      "_layouts/child_partial.html.liquid" => <<~LIQUID,
        <p>Child partial content</p>
        <p>Title: {{ entry.title }}</p>
      LIQUID
      "entry.md" => <<~MARKDOWN
        ---
        date: 2020-03-01 12:00:00 -0800
        title: Entry Title
        ---

        Entry content.
      MARKDOWN
    }
    config = <<~YAML
      layout_file: ../_layouts/layout.html.liquid
      uri_strategy: pretty_yyyy_mm_dd
    YAML
    build_with(files:, config:)

    visit "/entry/index.html"
    expect(page).to have_text "Parent partial content"
    expect(page).to have_text "Date: 2020-03-01T12:00:00-08:00"
    expect(page).to have_text "Child partial content"
    expect(page).to have_text "Title: Entry Title"
    expect(page).to have_text "Entry content"
  end
end
