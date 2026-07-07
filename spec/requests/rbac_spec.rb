# frozen_string_literal: true

require "hanami_helper"

RSpec.describe "Admin authorization", :db do
  include_context "with JWT"

  let(:headers) { {"HTTP_AUTHORIZATION" => access_token, "CONTENT_TYPE" => "application/json"} }

  context "when the user is a member" do
    let(:user) { Factory[:user, :verified, role: "member"] }

    it "forbids an admin-only endpoint" do
      get routes.path(:api_firmwares), {}, headers
      expect(last_response.status).to eq(403)
    end

    it "forbids delete actions" do
      delete routes.path(:api_device, id: 1), {}, headers
      expect(last_response.status).to eq(403)
    end

    it "allows non-admin resources" do
      get routes.path(:api_devices), {}, headers
      expect(last_response.status).not_to eq(403)
    end
  end

  context "when the user is an admin" do
    let(:user) { Factory[:user, :verified, role: "admin"] }

    it "allows an admin-only endpoint" do
      get routes.path(:api_firmwares), {}, headers
      expect(last_response.status).not_to eq(403)
    end
  end
end
