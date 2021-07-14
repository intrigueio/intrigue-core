module Intrigue
  module Task
    class GithubAccountToRepositories < BaseTask
      def self.metadata
        {
          name: 'github_account_to_repositories',
          pretty_name: 'Github Account to Repositories',
          authors: ['jcran', 'maxim'],
          description: 'Uses the Github API to pull all known repositories for a GithubAccount.',
          references: ['https://docs.github.com/en/rest/reference/repos'],
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

        gh_client = retrieve_gh_client
        return if gh_client.nil?

        # get repos
        repos = retrieve_repositories(gh_client,account_name)

        # create repositories
        repos.each do |f|

          next unless f['full_name']

          entity_deets = { 'name' => f['full_name'] , 'github' => f.to_attrs }
          _create_entity "GithubRepository", entity_deets

        end

      end

      def retrieve_repositories(client, name, options={})

        repositories = []

        # try up to X times
        for i in 1..5
          begin
            _log "Getting repos for #{name} ... #{i}"
            repositories << client.repos(name) # we dont need to use org_repos since this is only retrieving public repos
            next_url = client.last_response.rels[:next].href if client.last_response.rels[:next]

            while next_url
              sleep 10
              _log "Getting: #{next_url}"
              repositories << client.get(next_url)

              # get the next url
              break unless client.last_response.rels[:next]
              next_url = client.last_response.rels[:next].href
            end

            # we're complete, no need to retry
            break

          rescue Octokit::TooManyRequests, Octokit::AbuseDetected => e
            _log_error "#{e}\nRate limiting hit on attempt #{i}. Retrying."
            sleep 300
            next
          end
        end

        # drop forked
        if options[:ignore_forked]
          out = repositories.flatten.select { |r| r['fork'] == false } # ignore forked repos
        else
          out = repositories.flatten
        end

      out
      end


      def retrieve_gh_client
        gh_client = initialize_gh_client
        _log_error 'Unable to search across Github without authentication; aborting task.' if gh_client.nil?
        gh_client
      end

    end
  end
end
