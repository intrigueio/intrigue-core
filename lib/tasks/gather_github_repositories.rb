module Intrigue
  module Task
    class GatherGithubRepositories < BaseTask
      include Intrigue::Task::Web

      def self.metadata
        {
          name: 'gather_github_repositories',
          pretty_name: 'Gather Github Repositories',
          authors: ['maxim'],
          description: 'Gathers repositories belonging to a Github account (personal/organization). This task uses either authenticated or unauthenticated techniques based on whether a Github Access Token is provided. Please note that the unauthenticated technique is rate limited at 60 requests per hour, while the authenticated technique allows for 5,000 requests per hour. <br><br>Task Options:<br><ul><li><b>account</b> - (default value: empty) - Gather a specific account\'s repositories. This value is required for when attempting to retrieve the repositories without providing a Github Access Token. If a Github Access Token is provided, this can be used to retrieve Github Repositories of another account without being limited to 60 requests per hour. However leave this value blank if you are attempting to retrieve the repositories associated with the provided Github Access Token as this will not retrieve private repositories due to how Github\'s API works.</li></ul>',
          references: ['https://docs.github.com/en/rest'],
          type: 'discovery',
          passive: true,
          allowed_types: ['String'],
          example_entities: [{ 'type' => 'String', 'details' => { 'name' => '__IGNORE__', 'default' => '__IGNORE__' } }],
          allowed_options: [
            { name: 'account', regex: 'alpha_numeric', default: '' }
          ],
          created_types: ['GithubRepository']
        }
      end

      ## Default method, subclasses must override this
      def run
        super

        gh_client = initialize_gh_client
        account = _get_option('account')

        repos = gh_client ? retrieve_repos_authenticated(gh_client, account) : retrieve_repos_unauthenticated(account)

        _log 'No repositories discovered.' if repos.nil?
        return if repos.nil?

        _log_good "Retrieved #{repos.size} repositories."
        repos.each { |r| create_repo_entity(r) }
      end

      def retrieve_repos_authenticated(client, name)
        client.auto_paginate = true

        retrieved_repos = client_api_request(client, name)
        repos = retrieved_repos.map { |r| r['full_name'] } if retrieved_repos

        repos
      end

      def client_api_request(client, name)
        begin
            return client.repos if name.empty?
            return nil unless account_exists?(name)

            repositories = if org?(name)
                             client.org_repos(name, { 'type' => 'all' })
                           else
                             client.repos(name)
                           end
        rescue Octokit::TooManyRequests, Octokit::AbuseDetected
          _log_error 'Rate limiting via authenticated techniques reached.'
          return nil
          end

        repositories
      end

      def http_get_json_body(url)
        r = http_get_body(url)
        return nil if http_rate_limiting?(r)

        begin
          parsed_response = JSON.parse(r)
        rescue JSON::ParserError
          _log_error 'Cannot parse JSON.'
          return nil
        end

        parsed_response
      end

      def http_rate_limiting?(response)
        rate_limiting = response.include? 'API rate limit exceeded'
        _log 'HTTP requests are being rate limited.' if rate_limiting
        rate_limiting
      end

      def account_exists?(name)
        response = http_get_json_body("https://api.github.com/users/#{name}")

        exists = response['message'] != 'Not Found'
        _log_error "#{name} is not a valid Github user/repository; exiting." unless exists

        exists
      end

      def org?(name)
        response = http_get_json_body("https://api.github.com/users/#{name}")
        response['type'].eql? 'Organization'
      end

      def retrieve_repos_unauthenticated(name)
        return nil unless account_exists?(name) # if account doesnt exist return nil

        pages = return_max_pages(name)
        return nil if pages.nil?

        search_urls = 1.step(pages.to_i).map { |p| "https://api.github.com/users/#{name}/repos?page=#{p}" }

        output = []
        workers = (0...20).map do
          results = api_http_request(search_urls, output)
          [results]
        end
        workers.flatten.map(&:join)

        output ? output.flatten : nil
      end

      def api_http_request(input_q, output_q) # change the name of this method
        t = Thread.new do
          until input_q.empty?
            while url = input_q.shift
              results = http_get_json_body(url)
              next if results.nil?

              # what happens if we hit rate limiting here?
              output_q << results.map { |res| res['full_name'] }
            end
          end
        end
        t
        # rate limit occurs when 403 forbidden code returns
      end

      def return_max_pages(account)
        r = http_request(:get, "https://api.github.com/users/#{account}/repos")
        max_pages_header = r.headers['link']

        return nil unless r.code == '200' # 404 repo does not exist / or other issues such as rate limiting
        return 1 if r.code == '200' && max_pages_header.nil? # only one page

        max_pages = max_pages_header.scan(/\?page=(\d*)/i).last.first
        max_pages
      end

      def create_repo_entity(repo)
        _create_entity 'GithubRepository', {
          'name' => repo,
          'repository_name' => repo,
          'uri' => "https://github.com/#{repo}"
        }
      end

      def initialize_gh_client
        begin
          access_token = _get_task_config('github_access_token')
        rescue MissingTaskConfigurationError
          _log 'Github Access Token is not set in task_config.'
          _log 'Please note this severely limits the results due to rate limiting along with only being able to gather public repositories.'
          return nil
        end

        verify_gh_access_token(access_token) # returns client if valid else nil
      end

      def verify_gh_access_token(token)
        client = Octokit::Client.new(access_token: token)
        begin
          client.user
        rescue Octokit::Unauthorized, Octokit::TooManyRequests
          _log_error 'Github Access Token invalid either due to invalid credentials or rate limiting reached; defaulting to unauthenticated.'
          return nil
        end
        client
      end
    end
  end
end
