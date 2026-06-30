# frozen_string_literal: true

require "hanami/view"

module Terminus
  module Views
    module Parts
      # The device log presenter.
      class DeviceLog < Hanami::View::Part
        def level_class
          case level
            when "debug" then "bit-pill-hint"
            when "info" then "bit-pill-active"
            when "warn" then "bit-pill-caution"
            when "error" then "bit-pill-alert"
            when "fatal" then "bit-pill-danger"
            else "bit-pill-dark"
          end
        end
      end
    end
  end
end
