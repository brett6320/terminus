# frozen_string_literal: true

require "hanami_helper"

RSpec.describe "SSO diagnostic", :db do
  it "reads OIDC_ISSUER from settings" do
    expect(Hanami.app[:settings].oidc_issuer).to eq("https://idp.test")
  end

  it "renders the login page with the OIDC button", :aggregate_failures do
    get "/login"

    expect(last_response.status).to eq(200)
    expect(last_response.body).to include("Login")
    expect(last_response.body).to include("Sign in with OpenID Connect")
  end
end
