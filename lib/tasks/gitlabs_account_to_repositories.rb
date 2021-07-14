module Intrigue
  module Task
    class GitlabAccountToRepositories < BaseTask
      def self.metadata
        {
          name: 'gitlab_account_to_repositories',
          pretty_name: 'Gitlab Account to Repositories',
          authors: ['maxim'],
          description: 'Uses the Gitlab API to pull all known repositories for a GitlabAccount.',
          references: ['https://docs.gitlab.com/ee/api/'],
          type: 'discovery',
          passive: false,
          allowed_types: [ 'GithubAccount'],
          example_entities: [{ 'type' => 'GithubAccount', 'details' => { 'name' => 'intrigueio' } }],
          allowed_options: [],
          created_types: ["GithubRepository"]
        }
      end

      ## Default method, subclasses must override this
      def run
        super
        account_name = _get_entity_name
        retrieve_repositories(account_name)
        # retrieve_gitlabs_access_token

      end

      def retrieve_repositories(username)
        total_pages = http_request(:get, "https://gitlab.com/api/v4/users/#{username}/projects").headers['x-total-pages']

        _log "No user exists by the name of #{username}" if total_pages.nil?
        return if total_pages.nil?

        urls = (1..total_pages.i).map { |page| "https://gitlab.com/api/v4/users/#{username}/projects?page=#{page}&per_page=100" }

        urls.map { |u| parse_repos_from_page(u) }.flatten
      end

      def parse_repos_from_page(url)
        r = http_get_body(url)

        begin
          parsed_response = JSON.parse(r)
        rescue JSON::ParserError
          _log_error 'Cannot parse JSON.'
          return nil
        end

        parsed_response.map { |pr| pr['path_with_namespace'] }
      end

      def access_token_valid?(token)
        # send headers here
        # check if 401 
        # return false if 401
      end
      
     # returns wheter entity is a group
      def is_group?(name, access_token)
        http_request(:get, "https://gitlab.com/api/v4/groups/#{account_name}").cod

      end

    end
  end
end