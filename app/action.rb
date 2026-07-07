# auto_register: false
# frozen_string_literal: true

require "dry/monads"
require "hanami/action"
require "initable"

module Terminus
  # The application base action.
  class Action < Hanami::Action
    include Dry::Monads[:result]

    # Paths reserved for administrators. Any DELETE is also admin-only (see #require_admin).
    ADMIN_PATHS = %r(\A/(api/)?(users|firmware|models)(/|\z))

    before :authorize
    after :audit

    protected

    def authorize request, response
      rodauth = request.env["rodauth"]

      return unless rodauth

      handle_rodauth_redirect rodauth, response do
        rodauth.require_account
        enforce_two_factor_setup rodauth
      end

      response[:current_user_id] = rodauth.account_id
      require_admin request
    end

    private

    # Records authenticated, state-changing requests to the tamper-evident audit chain.
    # Unauthenticated requests (e.g. device firmware endpoints) carry no actor and are skipped.
    def audit request, response
      return unless auditable? request, response

      Hanami.app["repositories.audit_event"].append(
        action: "#{request.env["REQUEST_METHOD"]} #{request.path}",
        actor_id: response.exposures[:current_user_id],
        metadata: {status: response.status}
      )
    end

    def auditable? request, response
      return false unless response.exposures[:current_user_id]

      %w[POST PUT PATCH DELETE].include? request.env["REQUEST_METHOD"]
    end

    # Restricts user/firmware/model management and all destructive (DELETE) actions to
    # administrators. Answers 403 Forbidden otherwise.
    def require_admin request
      return unless admin_request? request
      return if admin_user? request

      halt 403
    end

    def admin_request? request
      request.env["REQUEST_METHOD"] == "DELETE" ||
        request.path.match?(ADMIN_PATHS)
    end

    def admin_user? request
      id = request.env["rodauth"].account_id
      Hanami.app["repositories.user"].find(id).role.to_s == "admin"
    end

    # Forces multifactor enrollment for browser sessions when enabled. JWT (API) requests
    # are exempt since they authenticate without a second factor. Rodauth's
    # require_two_factor_setup redirects to the management page unless a factor is configured.
    def enforce_two_factor_setup rodauth
      return unless Hanami.app[:settings].mfa_required
      return if rodauth.use_jwt?

      rodauth.require_two_factor_setup
    end

    def handle_rodauth_redirect rodauth, response
      halted = catch(:halt) { yield }

      # :nocov:
      return unless halted

      code, headers, body = *halted

      rodauth.flash.next.each { |key, value| response.flash[key] = value }
      response.redirect headers["Location"], code

      throw :halt, [code, body]
      # :nocov:
    end
  end
end
