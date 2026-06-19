# frozen_string_literal: true

require "core"

module Terminus
  module Views
    module Screens
      # The new view.
      class New < View
        expose :models
        expose :screen
        expose :fields, decorate: false, default: Core::EMPTY_HASH
        expose :errors, decorate: false, default: Core::EMPTY_HASH
      end
    end
  end
end
