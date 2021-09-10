module Intrigue
  module Task
    module Enrich
      class GitlabProject < Intrigue::Task::BaseTask
        def self.metadata
          {
            name: 'enrich/gitlab_project',
            pretty_name: 'Enrich Gitlab Project',
            authors: ['jcran', 'maxim'],
            description: 'Ensures the entity is marked enriched. Used when there is no specific enrichment task!',
            references: [],
            type: 'enrichment',
            passive: true,
            allowed_types: ['GitlabProject'],
            example_entities: [
              { 'type' => 'GitlabProject',
                'details' => {
                  'name' => 'https://gitlab.intrigue.io/username/project'
                } }
            ],
            allowed_options: [],
            created_types: []
          }
        end

        ## Default method, subclasses must override this
        def run
          parsed_project_uri = parse_gitlab_uri(_get_entity_name)

          _set_entity_detail('project_name', parsed_project_uri.project)
          _set_entity_detail('project_uri', _get_entity_name)
          _set_entity_detail('project_account', parsed_project_uri.account)
          _set_entity_detail('repository_public', repo_public?(_get_entity_name))
        end

        def repo_public?(repo_uri)
          r = http_request(:get, repo_uri)
          r.code == '200'
        end

      end
    end
  end
end
