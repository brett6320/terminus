# frozen_string_literal: true

require "hanami_helper"

RSpec.describe "Audit trail", :db do
  include_context "with JWT"

  let(:model) { Factory[:model] }
  let(:playlist) { Factory[:playlist] }
  let(:audit) { Terminus::Repositories::AuditEvent.new }

  it "records an authenticated mutation" do
    post routes.path(:api_devices),
         {device: {model_id: model.id, playlist_id: playlist.id}}.to_json,
         "HTTP_AUTHORIZATION" => access_token,
         "CONTENT_TYPE" => "application/json"

    expect(audit.all.map(&:action)).to include("POST /api/devices")
  end

  it "records authentication events" do
    access_token

    expect(audit.all.map(&:action)).to include("login")
  end
end
