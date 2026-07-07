# frozen_string_literal: true

module Terminus
  module Aspects
    module Audit
      # Verifies the audit event hash chain, answering the first broken link (if any).
      class Verifier
        include Deps[repository: "repositories.audit_event"]
        include Dry::Monads[:result]

        def call
          prev_digest = Repositories::AuditEvent::GENESIS

          repository.all.each do |event|
            return Failure event unless valid? event, prev_digest

            prev_digest = event.digest
          end

          Success()
        end

        private

        def valid? event, prev_digest
          expected = Repositories::AuditEvent.digest_for(
            action: event.action,
            actor_id: event.actor_id,
            entity: event.entity,
            metadata: event.metadata,
            prev_digest:
          )

          event.prev_digest == prev_digest && event.digest == expected
        end
      end
    end
  end
end
