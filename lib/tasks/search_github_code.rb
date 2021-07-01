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
          allowed_types: ['String'],
          example_entities: [{ 'type' => 'String', 'details' => { 'name' => '__IGNORE__', 'default' => '__IGNORE__' } }], # what if we have multiple keywords? lets ignore this for now
          allowed_options: [
            { name: 'keywords', regex: 'alpha_numeric_list', default: '' },
          ], # use authentication?
          created_types: []
        }
      end

      ## Default method, subclasses must override this
      def run
        super

        gh_client = retrieve_gh_client
        return if gh_client.nil?

        gh_client.auto_paginate = true

        keywords = _get_option('keywords').delete(' ').split(',')
        return if keywords.empty?

        usernames = keywords.map { |keyword| search_code(gh_client, keyword) }.compact.flatten.uniq
        return if usernames.empty?

        repo_urls = usernames.map { |u| retrieve_repositories(gh_client, u) }.flatten

        _log_good "Retrieved #{repo_urls.size} repositories which may contain possible leaks."
        gitleaks_config = create_gitleaks_custom_config(keywords)

        results = threaded_gitleaks(repo_urls, gitleaks_config)
        return if results.empty?

        results.each {|result| create_suspicious_commit_issue(result) }
        # create issue with results

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
        # rate limit occurs when 403 forbidden code returns
      end

      # use github api to find all repositories containing specific keyword
      # return the usernames of all the repository owners
      def search_code(client, key)
        begin
          results = client.search_code(key, { 'per_page': 100 })['items']
        rescue Octokit::TooManyRequests, Octokit::AbuseDetected
          _log_error 'Rate limiting hit; exiting.'
          return nil
        end

        users = results.map { |r| r['repository']['owner']['login'] } unless results.empty?
        users
      end

      def retrieve_repositories(client, name)
        begin
          repositories = client.repos(name) # we dont need to use org_repos since this is only retrieving public repos
        rescue Octokit::TooManyRequests, Octokit::AbuseDetected
          _log_error 'Rate limiting via authenticated techniques reached.'
          return nil
        end

        non_forked = repositories.select { |r| r['fork'] == false }
        repository_urls = non_forked.map { |r| r['html_url'] } unless repositories.empty?

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
