# frozen_string_literal: true

require "hanami_helper"

RSpec.describe "Multifactor authentication", :db do
  context "when MFA is required" do
    before { allow(settings).to receive(:mfa_required).and_return true }

    it "forces multifactor setup before proceeding" do
      visit "/"

      expect(page).to have_current_path("/multifactor-manage")
    end
  end

  context "when MFA is not required" do
    it "does not force multifactor setup" do
      visit "/"

      expect(page).to have_current_path("/")
    end
  end
end
