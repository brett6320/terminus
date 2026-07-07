# frozen_string_literal: true

require "digest"
require "json"

module Terminus
  module Repositories
    # Appends tamper-evident, hash-chained audit events.
    class AuditEvent < DB::Repository[:audit_event]
      GENESIS = ("0" * 64).freeze
      LOCK_KEY = 4_372

      # The digest binds the event's content to the previous digest. Metadata is canonicalized
      # (recursively key-sorted) so it verifies identically after a jsonb round trip.
      def self.digest_for action:, actor_id:, entity:, metadata:, prev_digest:
        payload = [actor_id, action, entity, canonical(metadata), prev_digest]
        Digest::SHA256.hexdigest JSON.generate(payload)
      end

      def self.canonical value
        case value
          in Hash then value.to_h { |key, item| [key.to_s, canonical(item)] }
                            .sort.to_h
          in Array then value.map { canonical it }
          else value
        end
      end

      # Appends an event, linking it to the chain head under an advisory lock so concurrent
      # writers cannot fork the chain.
      def append action:, actor_id: nil, entity: nil, metadata: {}
        database.transaction do
          database.get Sequel.function(:pg_advisory_xact_lock, LOCK_KEY)
          prev_digest = head_digest
          digest = self.class.digest_for(action:, actor_id:, entity:, metadata:, prev_digest:)
          row = {
            actor_id:,
            action:,
            entity:,
            prev_digest:,
            digest:,
            metadata: Sequel.lit("?::jsonb", metadata.to_json)
          }

          dataset.insert row
        end
      end

      def all = audit_event.order(:id).to_a

      private

      def dataset = audit_event.dataset

      def database = dataset.db

      def head_digest
        row = dataset.order(:id).last
        row ? row.fetch(:digest) : GENESIS
      end
    end
  end
end
