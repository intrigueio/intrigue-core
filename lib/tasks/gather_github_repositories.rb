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
          allowed_options: [{ name: 'ignore_forks', regex: 'boolean', default: false }],
          created_types: ['GithubRepository'],
          queue: 'task_github'
        }
      end

      ## Default method, subclasses must override this
      def run
        super

        gh_client = initialize_gh_client
        repos = retrieve_repositories(gh_client)
        _log "Results obtained: #{repos.size}"
        return if repos.empty?

        repos.each { |r| create_github_repo_entity(r) }
      end

      def retrieve_repositories(client)
        repositories = []

        create_api_uri = determine_api_route(_get_entity_type_string)
        parser = create_parsers

        (1..10).each do |i|
          r = _github_api_call(create_api_uri.call(i), client&.access_token)
          preflight = preflight_check(r) if i == 1
          break unless preflight

          parsed_r = _parse_json_response(r.body)
          break if parsed_r.nil? || parsed_r.equal?('rate_exhaustion')

          parsed_r = parsed_r['items'] if _get_entity_type_string == 'GithubAccount' # dont like this
          break if parser.empty_checker.call(parsed_r) # no more resp

          parsed_r = parser.del_forks.call(parsed_r) if _get_option('ignore_forks')

          repositories << parser.repo_parser.call(parsed_r)
          sleep(2)
        end
        repositories.flatten
      end

      def preflight_check(response)
        good = true
        case response.code
        when '401'
          _log_error 'Authentication is required when using a String entity.'
          good = false
        when '422'
          _log_error 'Github Account does not exist; aborting.'
          good = false
        end
        good
      end

      # comment this
      def determine_api_route(entity_type)
        if entity_type == 'String'
          ->(x) { "https://api.github.com/user/repos?type=all&per_page=100&page=#{x}" }
        elsif entity_type == 'GithubAccount'
          account_name = extract_github_account_name(_get_entity_name)
          ->(x) { "https://api.github.com/search/repositories?page=#{x}&per_page=100&q=user:#{account_name}+fork:true" }
        end
      end

      # comment that
      def create_parsers
        empty_checker = ->(x) { x.empty? }
        repo_parser = ->(x) { x.map { |item| item['html_url'] } }
        forks_parser = ->(x) { x.reject { |item| item['fork'] } }

        Struct.new(:empty_checker, :repo_parser, :del_forks).new(empty_checker, repo_parser, forks_parser)
      end

      # comment this
      def _github_api_call(url, access_token = nil)
        headers = access_token ? { 'Authorization' => "Bearer #{access_token}" } : {}
        r = http_request(:get, url, nil, headers)

        exhausted = _check_rate_limiting(r)
        return exhausted if exhausted

        r
      end

      # comment that
      def _check_rate_limiting(response)
        if _api_requests_exhausted?(response)
          _log_error 'Exhausted the maximum amount of requests per hour; aborting.'
          'rate_exhaustion'
        elsif _secondary_rate_limit?(response)
          _log_error 'Rate limiting hit; will take a break before firing off additional requests.'
          sleep(300)
          'temp_rate_limit'
        end
      end

      # comment this
      def _api_requests_exhausted?(response)
        remaining = response.headers.transform_keys(&:downcase)['x-ratelimit-remaining']&.to_i
        remaining&.zero?
      end

      # comment that
      def _secondary_rate_limit?(response)
        response.body.include?('You have exceeded a secondary rate limit and have been temporarily blocked')
      end

      # comment this
      def _parse_json_response(response)
        JSON.parse(response)
      rescue JSON::ParserError
        _log_error 'Cannot parse JSON.'
      end

    end
  end
end