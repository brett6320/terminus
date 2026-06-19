# frozen_string_literal: true

require "core"

module Terminus
  module Views
    module Playlists
      module Items
        # The edit view.
        class Edit < View
          expose :screen_options, decorate: false
          expose :item
          expose :fields, decorate: false, default: Core::EMPTY_HASH
          expose :errors, decorate: false, default: Core::EMPTY_HASH
        end
      end
    end
  end
end
