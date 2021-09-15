module Intrigue
  module Task
    module Enrich
      class GitlabAccount < Intrigue::Task::BaseTask
        def self.metadata
          {
            name: 'enrich/gitlab_account',
            pretty_name: 'Enrich Gitlab Account',
            authors: ['jcran', 'maxim'],
            description: 'Ensures the entity is marked enriched. Used when there is no specific enrichment task!',
            references: [],
            type: 'enrichment',
            passive: true,
            allowed_types: ['GitlabAccount'],
            example_entities: [
              { 'type' => 'GitlabAccount',
                'details' => {
                  'name' => 'https://gitlab.com/intrigueio'
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
