# frozen_string_literal: true

require "hanami_helper"

RSpec.describe "SSO", :db, :js do
  let(:repository) { Terminus::Repositories::User.new }

  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:openid_connect] = OmniAuth::AuthHash.new(
      provider: "openid_connect",
      uid: "sso-uid-1",
      info: {email: "sso@test.io", name: "SSO User"}
    )
  end

  after do
    OmniAuth.config.mock_auth.delete :openid_connect
    OmniAuth.config.test_mode = false
  end

  it "signs in via OpenID Connect and provisions a local account", :aggregate_failures do
    visit "/login"
    click_button "Sign in with OpenID Connect"

    expect(page).to have_current_path("/")
    expect(repository.find_by(email: "sso@test.io")).not_to be(nil)
  end

  it "links to an existing local account with the same email", :aggregate_failures do
    user = Factory[:user, :verified, email: "sso@test.io"]
    Factory[:user_password_hash, id: user.id]

    visit "/login"
    click_button "Sign in with OpenID Connect"

    expect(page).to have_current_path("/")
    expect(repository.where(email: "sso@test.io").size).to eq(1)
  end
end
