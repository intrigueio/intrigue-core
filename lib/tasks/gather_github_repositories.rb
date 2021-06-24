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
          ], # github access token; # username/org to scan
          created_types: ['GithubRepository']
        }
      end

      ## Default method, subclasses must override this
      def run
        super

        access_token = retrieve_gh_access_token
        account = _get_option('account_name')

        repos = token ? retrieve_repos_authenticated(access_token, account) : retrieve_repos_unauthenticated(account)

        p repos

      end

      def retrieve_repos_authenticated(token, name); end

      def retrieve_repos_unauthenticated(name)
        # only 60 results per hour; 30 results per page
        pages = return_max_pages(name)
        return if pages.nil?

        # should we thread this?
      end

      def return_max_pages(account)
        r = http_request(:get, "https://api.github.com/users/#{account}/repos")
        max_pages_header = r.headers['link']

        return 1 if r.code == '200' && max_pages_header.nil? # only one page

        max_pages = max_pages_header.scan(/\?page=(\d*)/i).last.first
        max_pages
      end

      def create_repo_entities; end

      def retrieve_gh_access_token
        begin
          access_token = _get_task_config('github_access_token')
        rescue MissingTaskConfigurationError
          _log 'Github Access Token is not set in task_config.'
          _log 'Please note this severely limits the results due to rate limiting along with only being able to gather public repositories.'
          return nil
        end

        verify_gh_access_token(access_token)
      end

      def verify_gh_access_token
        valid = true
        client = Octokit::Client.new(access_token: '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')
        begin
          client.user
        rescue Octokit::Unauthorized
          _log_error 'Github Access Token invalid; defaulting to unauthenticated.'
          valid = false
        end
        valid
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
