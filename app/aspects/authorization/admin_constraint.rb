# frozen_string_literal: true

module Terminus
  module Aspects
    module Authorization
      # Restricts a mounted Rack application (e.g. Sidekiq Web) to administrators.
      class AdminConstraint
        FORBIDDEN = [403, {"content-type" => "text/plain"}, ["Forbidden\n"]].freeze

        def initialize app, container: Hanami.app
          @app = app
          @container = container
        end

        def call env
          return app.call env if admin? env

          FORBIDDEN
        end

        private

        attr_reader :app, :container

        def admin? env
          rodauth = env["rodauth"]
          return false unless rodauth

          user = container["repositories.user"].find rodauth.account_id
          return false unless user

          user.role.to_s == "admin"
        end
      end
    end
  end
end
