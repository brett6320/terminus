# frozen_string_literal: true

require "core"

module Terminus
  module Views
    module Firmware
      # The new view.
      class New < View
        expose :firmware
        expose :fields, decorate: false, default: Core::EMPTY_HASH
        expose :errors, decorate: false, default: Core::EMPTY_HASH
      end
    end
  end
end
