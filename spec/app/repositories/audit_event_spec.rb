# frozen_string_literal: true

require "hanami_helper"

RSpec.describe Terminus::Repositories::AuditEvent, :db do
  subject(:repository) { described_class.new }

  describe "#append" do
    it "links each event to the previous digest", :aggregate_failures do
      repository.append action: "first", metadata: {a: 1}
      repository.append action: "second", metadata: {b: 2}

      events = repository.all

      expect(events.first.prev_digest).to eq(described_class::GENESIS)
      expect(events.last.prev_digest).to eq(events.first.digest)
    end

    it "computes a digest that verifies after a jsonb round trip" do
      repository.append action: "test", metadata: {path: "/x", nested: {b: 1, a: 2}}
      event = repository.all.last

      expected = described_class.digest_for(
        action: event.action,
        actor_id: event.actor_id,
        entity: event.entity,
        metadata: event.metadata,
        prev_digest: event.prev_digest
      )

      expect(event.digest).to eq(expected)
    end
  end

  describe ".canonical" do
    it "sorts hash keys recursively regardless of order" do
      expect(described_class.canonical(b: 1, a: {d: 4, c: 3})).to eq(
        "a" => {"c" => 3, "d" => 4}, "b" => 1
      )
    end

    it "canonicalizes hashes nested within arrays" do
      expect(described_class.canonical([{b: 1, a: 2}, "x"])).to eq([{"a" => 2, "b" => 1}, "x"])
    end
  end
end
