# frozen_string_literal: true

require "hanami_helper"

RSpec.describe Terminus::Aspects::Authorization::AdminConstraint do
  subject(:constraint) { described_class.new app, container: }

  let(:app) { proc { [200, {}, %w[ok]] } }
  let(:container) { {"repositories.user" => repository} }
  let(:repository) { instance_double Terminus::Repositories::User, find: user }

  def env_for(account_id) = {"rodauth" => (Struct.new(:account_id).new(account_id) if account_id)}

  describe "#call" do
    context "when the user is an administrator" do
      let(:user) { Struct.new(:role).new("admin") }

      it "delegates to the wrapped application" do
        expect(constraint.call(env_for(1)).first).to eq(200)
      end
    end

    context "when the user is a member" do
      let(:user) { Struct.new(:role).new("member") }

      it "answers forbidden" do
        expect(constraint.call(env_for(1)).first).to eq(403)
      end
    end

    context "when the account is unknown" do
      let(:user) { nil }

      it "answers forbidden" do
        expect(constraint.call(env_for(1)).first).to eq(403)
      end
    end

    context "when not logged in" do
      let(:user) { nil }

      it "answers forbidden" do
        expect(constraint.call(env_for(nil)).first).to eq(403)
      end
    end
  end
end
