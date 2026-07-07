# frozen_string_literal: true

module Terminus
  module Relations
    # The audit event relation.
    class AuditEvent < DB::Relation
      schema :audit_event, infer: true
    end
  end
end
