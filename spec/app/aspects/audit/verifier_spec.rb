# frozen_string_literal: true

require "hanami_helper"

RSpec.describe Terminus::Aspects::Audit::Verifier, :db do
  subject(:verifier) { described_class.new }

  let(:repository) { Terminus::Repositories::AuditEvent.new }

  describe "#call" do
    it "succeeds for an empty chain" do
      expect(verifier.call).to be_success
    end

    it "succeeds for an intact chain" do
      repository.append action: "one"
      repository.append action: "two", metadata: {a: 1}

      expect(verifier.call).to be_success
    end

    it "fails when a stored event is altered" do
      repository.append action: "one"
      id = repository.all.last.id
      Hanami.app["db.gateway"].connection[:audit_event].where(id:).update(action: "tampered")

      expect(verifier.call).to be_failure
    end
  end
end
