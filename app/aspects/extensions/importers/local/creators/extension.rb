# frozen_string_literal: true

require "dry/monads"
require "initable"

module Terminus
  module Aspects
    module Extensions
      module Importers
        module Local
          module Creators
            # Creates extension.
            class Extension
              include Deps[:logger, repository: "repositories.extension"]
              include Initable[error_joiner: proc { Terminus::Aspects::Errors::ResultJoiner }]
              include Dry::Monads[:result]

              def initialize(schema: Schemas::Extension, problem_detail: Aspects::ProblemDetail, **)
                @schema = schema
                @problem_detail = problem_detail
                super(**)
              end

              def call attributes
                schema.call(attributes)
                      .to_monad
                      .alt_map { error_joiner.call "Extension", it }
                      .fmap { create it.to_h }
              rescue ROM::SQL::UniqueConstraintError => error
                Failure problem_detail.duplicate(error.message, nil).detail
              end

              private

              attr_reader :schema, :problem_detail

              def create(attributes) = repository.create(attributes).tap { log it }

              def log extension
                logger.debug(tags: [{extension_id: extension.id}]) { "Imported extension." }
              end
            end
          end
        end
      end
    end
  end
end
