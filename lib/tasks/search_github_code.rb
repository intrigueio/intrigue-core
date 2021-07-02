module Intrigue
  module Task
    class SearchGithubCode < BaseTask
      def self.metadata
        {
          name: 'search_github_code',
          pretty_name: 'Search Github Code',
          authors: ['maxim'],
          description: 'balbalablabala',
          references: ['000000'],
          type: 'discovery',
          passive: false,
          allowed_types: ['String', 'UniqueKeyword'],
          example_entities: [{ 'type' => 'String', 'details' => { 'name' => 'intrigue.io' } }],
          allowed_options: [],
          created_types: []
        }
      end

      ## Default method, subclasses must override this
      def run
        super
        keyword = _get_entity_name

        gh_client = retrieve_gh_client
        return if gh_client.nil?

        gh_client.auto_paginate = true

        repo_urls = search_code(gh_client, keyword).compact.uniq
        return if repo_urls.nil?

        _log_good "Found #{repo_urls.size} repositories which may contain possible leaks."

        gitleaks_config = create_gitleaks_custom_config([keyword]) # pass in array to helper as it expects one
        results = threaded_gitleaks(repo_urls, gitleaks_config)

        results.each { |result| create_suspicious_commit_issue(result) } unless results.empty?
      end

      def threaded_gitleaks(repos, gitleaks_config)
        output = []
        workers = (0...10).map do
          results = run_gitleaks_thread(repos, output, _get_task_config('github_access_token'), gitleaks_config)
          [results]
        end
        workers.flatten.map(&:join)

        output
      end

      def run_gitleaks_thread(input_q, output_q, access_token, config) # change the name of this method
        t = Thread.new do
          until input_q.empty?
            while repo = input_q.shift
              results = run_gitleaks(repo, access_token, config)
              next if results.nil?

              output_q << results
            end
          end
        end
        t
      end

      # use github api to find all repositories containing specific keyword
      # return all the repos belonging to the usernames found
      def search_code(client, key)
        begin
          results = client.search_code(key, { 'per_page': 100 })['items']
        rescue Octokit::TooManyRequests, Octokit::AbuseDetected
          _log_error 'Rate limiting hit; exiting.'
          return nil
        end

        users = results.map { |r| r['repository']['owner']['login'] } unless results.empty?
        repo_urls = users.map { |u| retrieve_repositories(client, u) }.flatten unless users.empty?
        repo_urls
      end

      def retrieve_repositories(client, name)
        begin
          repositories = client.repos(name) # we dont need to use org_repos since this is only retrieving public repos
        rescue Octokit::TooManyRequests, Octokit::AbuseDetected
          _log_error 'Rate limiting via authenticated techniques reached.'
          return nil
        end

        non_forked = repositories.select { |r| r['fork'] == false } # ignore forked repos
        repository_urls = non_forked.map { |r| r['html_url'] } unless non_forked.empty? # extract repo urls

        repository_urls
      end

      def retrieve_gh_client
        gh_client = initialize_gh_client
        _log_error 'Unable to search across Github without authentication; aborting task.' if gh_client.nil?
        gh_client
      end

    end
  end
end
