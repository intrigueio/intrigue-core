module Intrigue
  module Task
    class GatherGithubRepositories < BaseTask
      include Intrigue::Task::Web

      def self.metadata
        {
          name: 'Gather Github Repositories',
          pretty_name: 'Gather Github Repositories',
          authors: ['jcran', 'maxim'],
          description: 'Gathers repositories belonging to a Github account (personal/organization). This task uses either authenticated or unauthenticated techniques based on whether a Github Access Token is provided. Please note that the unauthenticated technique is rate limited at 60 requests per hour, while the authenticated technique allows for 5,000 requests per hour. <br><br>Allowed Task Entities:<br><ul><li><b>String</b> - (default value: __IGNORE__) - <b>Requires Valid Github Access Token</b>. Leave this default if you would like to retrieve all repositories belonging to the access token.</li><li><b>Github Account</b> - (Default value: intrigueio) - If you would like to retrieve repositories for a specific Github account, use this entity. This will use either authenticated or unauthenticated techniques to retrieve repositories belonging to the account specified.</li></ul>',
          references: ['https://docs.github.com/en/rest'],
          type: 'discovery',
          passive: true,
          allowed_types: ['String', 'GithubAccount'],
          example_entities: [{ 'type' => 'String', 'details' => { 'name' => '__IGNORE__', 'default' => '__IGNORE__' } },
                             { 'type' => 'GithubAccount', 'details' => { 'name' => 'intrigueio', 'default' => 'https://github.com/intrigueio' } }],
          allowed_options: [{ name: 'ignore_forked', regex: 'boolean', default: false }],
          created_types: ['GithubRepository'],
          queue: 'task_github'
        }
      end

      ## Default method, subclasses must override this
      def run
        super

        gh_client = initialize_gh_client
        account = extract_github_account_name(_get_entity_name) if _get_entity_type_string == 'GithubAccount'
        repos = retrieve_repositories(gh_client, account)
        repos.each { |r| create_github_repo_entity(r) }
      end

      def retrieve_repositories(client, name)
        repositories = []

        return_api_uri = determine_api_route(name)

        (1..10).each do |i|
          r = _http_get_json_body(return_api_uri.call(i), client.access_token)
          empty_check, repo_parser = determine_parser(name)

          break if empty_check.call(r)

          repositories << repo_parser.call(r)
        end
        repositories.flatten!
      end

      def determine_api_route(name)
        if name.nil?
          -> (x) { "https://api.github.com/user/repos?type=all&per_page=100&page=#{x}" }
        else
          use_fork = _get_option('ignore_forked') == false
          -> (x) { "https://api.github.com/search/repositories?page=#{x}&per_page=100&q=user:#{name}+fork:#{use_fork}" }
        end
      end

      def determine_parser(name)
        if name.nil?
         return -> (x) { x.empty? }, -> (x) { x.map { |item| item['html_url']} }
        else
         return -> (x) { x['items'].empty? }, -> (x) { x['items'].map { |item| item['html_url'] } }
        end
      end

      def _github_account_exists?(name, access_token = nil)
        r = _http_get_json_body("https://api.github.com/users/#{name}", access_token)
        exists = response['message'] != 'Not Found' if r

        _log_error "#{name} is not a valid Github user/repository; exiting." unless exists
        exists
      end

      def _http_get_json_body(url, access_token = nil)
        headers = access_token ? { 'Authorization' => "Bearer #{access_token}" } : {}
        r = http_request(:get, url, nil, headers).body
        # return nil if http_rate_limiting?(r)

        _parse_json_response(r)
      end

      def _parse_json_response(response)
        JSON.parse(response)
      rescue JSON::ParserError
        _log_error 'Cannot parse JSON.'
      end
    end
  end
end
