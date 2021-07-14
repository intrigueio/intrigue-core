module Intrigue
  module Task
    module Enrich
      class GitlabProject < Intrigue::Task::BaseTask
        def self.metadata
          {
            name: 'enrich/gitlab_project',
            pretty_name: 'Gitlab Project Enrichment',
            authors: ['jcran', 'maxim'],
            description: 'Ensures the entity is marked enriched. Used when there is no specific enrichment task!',
            references: [],
            type: 'enrichment',
            passive: true,
            allowed_types: ['GitlabProject'],
            example_entities: [
              { 'type' => 'GitlabProject',
                'details' => {
                  'name' => 'intrigueio/intrigue-core'
                } }
            ],
            allowed_options: [],
            created_types: []
          }
        end

        ## Default method, subclasses must override this
        def run
          _log "Marking #{_get_entity_type_string}: #{_get_entity_name} enriched!"
        end
      end
    end
  end
end
