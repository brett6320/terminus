# frozen_string_literal: true

module Terminus
  module Views
    module Designs
      # The index view.
      class Index < View
        expose :name, default: :terminus_designer
        expose :label, default: "Designer"
      end
    end
  end
end
