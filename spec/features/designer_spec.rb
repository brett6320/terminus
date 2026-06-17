# frozen_string_literal: true

require "hanami_helper"

RSpec.describe "Designer", :db do
  it "renders page" do
    visit routes.path(:designs)
    expect(page).to have_text("Welcome to the Terminus designer!")
  end
end
