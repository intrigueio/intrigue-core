module Intrigue
  module Task
    class GatherGithubRepositories < BaseTask
      include Intrigue::Task::Web

      def self.metadata
        {
          name: 'gather_github_repositories',
          pretty_name: 'Gather Github Repositories',
          authors: ['maxim'],
          description: 'balbalabla',
          references: ['http://balbalabla'],
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

      # NEED TO CATCH RATE LIMIT EXCEPTION

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
        return client.repos if name.empty?
        return nil unless account_exists?(name)

        repositories = if org?(name)
                         client.org_repos(name, { 'type' => 'all' })
                       else
                         client.repos(name)
                       end
        repositories
      end

      def abstract_github_http_request(url)
        r = http_get_body(url)
        begin
          parsed_response = JSON.parse(r)
        rescue JSON::ParserError
          _log_error 'Cannot parse JSON.'
          return nil
        end

        parsed_response
      end

      def account_exists?(name)
        response = abstract_github_http_request("https://api.github.com/users/#{name}")

        exists = response['message'] != 'Not Found'
        _log_error "#{name} is not a valid Github user/repository; exiting." unless exists

        exists
      end

      def org?(name)
        response = abstract_github_http_request("https://api.github.com/users/#{name}")
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
              results = abstract_github_http_request(url)
              next if results.nil?
              # what happens if we hit rate limiting here?
              output_q << results.map { |res| res['full_name'] }
            end
          end
        end
        t
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
        rescue Octokit::Unauthorized
          _log_error 'Github Access Token invalid; defaulting to unauthenticated.'
          return nil
        end
        client
      end
    end
  end
end

# gather_github_repositories
# - uses gh token from task_config [optional]
# - username/organization [optional] ->
# - if you have key but no user/organization provided get all repositories that key can access
#
# - if you have and user/organization only get repos from specific users
#
# - if you only get username/organization but no key you only get public ones [experimental]
#
# once repo is found -> create github repo entity
#
# github repo entity -> enrich task -> gitleaks should be called from enrich task
