# auto_register: false
# frozen_string_literal: true

require "dry/monads"
require "hanami/action"
require "initable"

module Terminus
  # The application base action.
  class Action < Hanami::Action
    include Dry::Monads[:result]

    before :authorize

    protected

    def authorize request, response
      rodauth = request.env["rodauth"]

      return unless rodauth

      handle_rodauth_redirect rodauth, response do
        rodauth.require_account
        enforce_two_factor_setup rodauth
      end

      response[:current_user_id] = rodauth.account_id
    end

    private

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
