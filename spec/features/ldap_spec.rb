# frozen_string_literal: true

require "hanami_helper"
require "net/ldap"

RSpec.describe "LDAP authentication", :db do
  before do
    allow(settings).to receive_messages(
      ldap_host: "ldap.test",
      ldap_port: 389,
      ldap_bind_pattern: "uid=%s,dc=test"
    )

    # The shared "with login" context signs a user in; start from a signed-out state.
    visit "/logout"
    click_button "Logout"
  end

  def sign_in email, password
    visit "/login"
    fill_in "login", with: email
    click_button "Login"
    fill_in "Password", with: password
    click_button "Login"
  end

  context "when the account has no local password" do
    let(:ldap_user) { Factory[:user, :verified, email: "ldap@test.io"] }

    it "authenticates against the directory on a successful bind" do
      ldap_user
      allow(Net::LDAP).to receive(:new).and_return(instance_double(Net::LDAP, bind: true))

      sign_in "ldap@test.io", "directory-password"

      expect(page).to have_text("You have been logged in.")
    end
  end

  context "when the account has a local password" do
    it "authenticates locally without contacting the directory" do
      allow(Net::LDAP).to receive(:new).and_return(instance_double(Net::LDAP, bind: false))

      sign_in user.email, "password"

      expect(page).to have_text("You have been logged in.")
    end
  end
end
