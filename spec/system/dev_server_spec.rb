require "capybara/rspec"

require "spec_helper"
require "lifer/dev/server"

Capybara.app = Lifer::Dev::Server.rack_app
Capybara.server = :puma, {Silent: true}

RSpec.describe "dev server", type: :system do
  before do
    spec_lifer! && Lifer.build!
  end

  it "serves only the current Lifer project" do
    visit "/not-a-page.html"
    expect(page).to have_text "404 Not Found"

    visit "/tiny_entry.html"
    expect(page).to have_text "A testable entry"

    expect do
      visit "/not-a-valid-file-type.zzz"
    end.to raise_error NotImplementedError
  end
end
