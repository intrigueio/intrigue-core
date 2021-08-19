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
          allowed_types: ['UniqueKeyword', 'String'],
          example_entities: [{ 'type' => 'UniqueKeyword', 'details' => { 'name' => 'intrigue.io' } }],
          allowed_options: [{ name: 'run_gitleaks_with_custom_keyword', regex: 'boolean', default: true }],
          created_types: ['GithubRepository'],
          queue: 'task_github'
        }
      end

      ## Default method, subclasses must override this
      def run
        super
        keyword = _get_entity_name

        gh_client = retrieve_gh_client
        return if gh_client.nil?

        findings = search_code(gh_client, keyword)
        return if findings.nil?

        _log_good "Found #{findings.size} repositories which may contain possible leaks."

        findings.each do |f|
          e = create_github_repo_entity(f) # create repositories as entity & return entity to be passed to start_task method

          # run gitleaks because the search_code api only checks master branch ,latest commit, files less than 384kb
          # however if the keyword is found in the latest commit, there is a high chance its most likely found in older commits
          # as such, gitleaks is ran using the custom keyword therefore the scan being quicker and yielding more results
          if _get_option('run_gitleaks_with_custom_keyword')
            start_task('task', @entity.project, nil, 'gitleaks', e, 1, [{ 'name' => 'custom_keywords', 'value' => keyword }])
          end
        end
      end

      # use github api to find all repositories containing specific keyword
      # return all the repos belonging to the usernames found
      def search_code(client, key)
        results = []

        client_api_request_done = false
        next_url = nil
        # try up to X times -> in case rate limiting occurs
        (1..5).each do |i|
          _log "Searching for #{key}"
          if client_api_request_done == false
            results << client.search_code(key)['items']
            client_api_request_done = true
          end

          next_url = client.last_response.rels[:next].href if client.last_response.rels[:next]

          while next_url
            sleep 10
            _log "Getting: #{next_url}"
            results << client.get(next_url)['items']

            # get the next url
            break unless client.last_response.rels[:next]

            next_url = client.last_response.rels[:next].href
          end

          # we're complete, no need to retry
          break
        rescue Octokit::AbuseDetected, Octokit::Forbidden
          _log_error "Rate limiting hit on attempt #{i}; Retrying in 5 minutes."
          sleep 300
          next
        rescue Octokit::TooManyRequests
          # the only option here is to sleep for 1 hour, but that will hold up other tasks in the queue
          _log_error 'Exhausted max requests per hour; exiting.'
          return nil
        end

        parse_results(results)
      end

      def parse_results(repositories)
        repositories.flatten!.compact!
        _log 'Unable to find any repositories which contain the provided keyword.' if repositories.empty?
        return if repositories.empty?

        repositories.map { |repo| repo['repository']['full_name'] }.uniq
      end

      def retrieve_gh_client
        gh_client = initialize_gh_client
        _log_error 'Unable to search across Github without authentication; aborting task.' if gh_client.nil?

        gh_client&.fetch('client')
      end

    end
  end
end
