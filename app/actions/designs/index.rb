# frozen_string_literal: true

module Terminus
  module Actions
    module Designs
      # The index action.
      class Index < Action
        def handle(*, response) = response.render view
      end
    end
  end
end
