# frozen_string_literal: true

require "hanami_helper"

RSpec.describe "Rack::Attack", :db do
  let(:public_ip) { {"REMOTE_ADDR" => "203.0.113.5", "HTTP_USER_AGENT" => "test-agent"} }
  let(:trusted_ip) { {"REMOTE_ADDR" => "127.0.0.1", "HTTP_USER_AGENT" => "test-agent"} }

  before do
    store = Rack::Attack.cache.store
    keys = store.call "KEYS", "#{Rack::Attack.cache.prefix}*"
    store.call "DEL", *keys unless keys.empty?
  end

  describe "admin IP blocklist" do
    it "forbids Sidekiq Web from an untrusted IP" do
      get "/sidekiq", {}, public_ip
      expect(last_response.status).to eq(403)
    end

    it "forbids user management from an untrusted IP" do
      get "/users", {}, public_ip
      expect(last_response.status).to eq(403)
    end

    it "allows admin paths from a trusted (loopback) IP" do
      get "/users", {}, trusted_ip
      expect(last_response.status).not_to eq(403)
    end
  end

  describe "throttling" do
    # POST as JSON so Rodauth's json mode skips CSRF; rack-attack still counts each request.
    def login_attempt env
      post "/login", "{}", env.merge("CONTENT_TYPE" => "application/json")
    end

    it "throttles repeated login attempts from an untrusted IP" do
      (LOGIN_LIMIT + 1).times { login_attempt public_ip }
      expect(last_response.status).to eq(429)
    end

    it "does not throttle login from safelisted IPs" do
      (LOGIN_LIMIT + 1).times { login_attempt trusted_ip }
      expect(last_response.status).not_to eq(429)
    end
  end

  describe "blank user agent blocklist" do
    it "forbids a blank user agent from an untrusted IP" do
      get "/", {}, "REMOTE_ADDR" => "203.0.113.5"
      expect(last_response.status).to eq(403)
    end

    it "exempts the health check" do
      get "/up", {}, "REMOTE_ADDR" => "203.0.113.5"
      expect(last_response.status).not_to eq(403)
    end

    it "allows a present user agent" do
      get "/", {}, public_ip
      expect(last_response.status).not_to eq(403)
    end
  end
end
