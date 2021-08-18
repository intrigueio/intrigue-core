module Intrigue
  module Task
    module Enrich
      class GithubRepository < Intrigue::Task::BaseTask
        def self.metadata
          {
            name: 'enrich/github_repository',
            pretty_name: 'Github Repository Enrichment',
            authors: ['maxim'],
            description: 'Ensures the entity is marked enriched. Used when there is no specific enrichment task!',
            references: [],
            type: 'enrichment',
            passive: true,
            allowed_types: ['GithubRepository'],
            example_entities: [
              { 'type' => 'GithubRepository',
                'details' => {
                  'name' => 'https://github.com/intrigueio/intrigue-core'
                } }
            ],
            allowed_options: [],
            created_types: []
          }
        end

        ## Default method, subclasses must override this

        def run
          repo_name = extract_full_repo_name(_get_entity_name)

          _set_entity_detail('owner', repo_name.split('/').first)
          _set_entity_detail('repository_name', repo_name.split('/')[1])
          _set_entity_detail('repository_uri', "https://github.com/#{repo_name}")
          _set_entity_detail('repository_public', repo_public?(repo_name))
        end

        def repo_public?(repo_full_name) 
          # if non 404 we'll just assume its private
          r = http_request(:get, "https://api.github.com/repos/#{repo_full_name}")
          r.code == '200'
        end

      end
    end
  end
end
