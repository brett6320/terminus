# frozen_string_literal: true

module Terminus
  module Actions
    module Designs
      # The edit action.
      class Edit < Action
        include Deps[:htmx_layout, template_repository: "repositories.screen_template"]

        params { required(:id).filled :integer }

        def handle request, response
          parameters = request.params

          halt :unprocessable_content unless parameters.valid?

          response.render view,
                          template: template_repository.find(parameters[:id]),
                          layout: htmx_layout.call(request)
        end
      end
    end
  end
end
