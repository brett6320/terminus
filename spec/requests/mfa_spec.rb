# frozen_string_literal: true

require "hanami_helper"

RSpec.describe "MFA API exemption", :db do
  include_context "with JWT"

  before { allow(settings).to receive(:mfa_required).and_return true }

  it "does not force two-factor setup for JWT requests" do
    get routes.path(:api_devices),
        {},
        "HTTP_AUTHORIZATION" => access_token,
        "CONTENT_TYPE" => "application/json"

    expect(last_response.status).to eq(200)
  end
end
