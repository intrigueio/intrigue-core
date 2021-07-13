module Intrigue
  module Task
    class SearchGithubCode < BaseTask
      def self.metadata
        {
          name: 'search_github_code',
          pretty_name: 'Search Github Code',
          authors: ['jcran', 'maxim'],
          description: 'Uses the Github API to search across all repositories and finds those which contain the unique keyword specified.',
          references: ['https://docs.github.com/en/rest/reference/search#search-code'],
          type: 'discovery',
          passive: false,
          allowed_types: [ 'UniqueKeyword'],
          example_entities: [{ 'type' => 'UniqueKeyword', 'details' => { 'name' => 'intrigue.io' } }],
          allowed_options: [
            #{ name: "check_leaks", regex: "boolean", default: false },
          ],
          created_types: []
        }
      end

      ## Default method, subclasses must override this
      def run
        super
        keyword = _get_entity_name

        gh_client = retrieve_gh_client
        return if gh_client.nil?

        findings = search_code(gh_client, keyword)

        _log_good "Found #{findings.size} repositories which may contain possible leaks."

        # create repositories
        #repo_q = Queue.new
        findings.each do |f|

          next unless f["repository"] && f['repository']['full_name']

          full_name = f['repository']['full_name']
          #repo_q << full_name

          entity_deets = { 'name' => full_name , 'github' => f.to_attrs }
          _create_entity "GithubRepository", entity_deets

        end

        # optionally run gitleaks on found URLs
        #if get_option "check_leaks"
        #  gitleaks_config = create_gitleaks_custom_config([keyword]) # pass in array to helper as it expects one
        #  results = threaded_gitleaks(repo_q, gitleaks_config)
        #  results.each { |result| create_suspicious_commit_issue(result) } unless results.empty?
        #end

      end

      # use github api to find all repositories containing specific keyword
      # return all the repos belonging to the usernames found
      def search_code(client, key)

        results = []

        # try up to X times
        for i in 1..5
          begin

            _log "Searching for #{key}"
            results << client.search_code(key)['items']
            next_url = client.last_response.rels[:next].href

            while next_url
              sleep 10
              _log "Getting: #{next_url}"
              results << client.get(next_url)

              # get the next url
              break unless client.last_response.rels[:next]
              next_url = client.last_response.rels[:next].href
            end

            # we're complete, no need to retry
            break

          rescue Octokit::TooManyRequests, Octokit::AbuseDetected => e
            _log_error "#{e}\nRate limiting hit on attempt #{i}; Retrying."
            sleep 300
            next
          end
        end

        #users = results.flatten.map { |r| r['repository']['owner']['login'] }
      #repo_urls = users.map { |u| retrieve_repositories(client, u) }.flatten unless users.empty?
      results.flatten.compact.uniq
      end

      def retrieve_gh_client
        gh_client = initialize_gh_client
        _log_error 'Unable to search across Github without authentication; aborting task.' if gh_client.nil?
        gh_client
      end

    end
  end
end
