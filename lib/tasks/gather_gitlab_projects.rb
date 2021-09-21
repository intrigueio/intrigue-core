module Intrigue
  module Task
    class GatherGitlabProjects < BaseTask
      def self.metadata
        {
          name: 'gather_gitlab_projects',
          pretty_name: 'Gather Gitlab Projects',
          authors: ['maxim'],
          description: 'Uses the Gitlab API to pull all known repositories for a GitlabAccount.',
          references: ['https://docs.gitlab.com/ee/api/'],
          type: 'discovery',
          passive: false,
          allowed_types: ['GitlabAccount', 'GitlabCredential'],
          example_entities: [{ 'type' => 'GitlabAccount', 'details' => { 'name' => 'https://gitlab.intrigue.io/account' }},
                             { 'type' => 'GitlabCredential', 'details' => { 'name' => 'GitlabCreds1' }} ],
          allowed_options: [],
          created_types: ['GitlabProject']
        }
      end

      ## Default method, subclasses must override this
      def run
        super

        entity_info = parse_entity_information(_get_entity_type_string)
        return if entity_info.nil?

        projects = gather_gitlab_projects(entity_info)
        _log "Gathered #{projects.size} projects!"
        return if projects.empty?

        projects.each { |r| _create_entity('GitlabProject', { 'name' => r }) }
      end

      def gather_gitlab_projects(entity_info)
        projects = []

        api_call_builder = return_uri_builder(entity_info)
        headers = { 'PRIVATE-TOKEN' => entity_info.token } if entity_info.token

        total_requests = _return_total_requests(api_call_builder, headers)
        return projects if total_requests.nil?

        (1..total_requests).each do |page|
          _log "Getting results from Page #{page}"
          outcome = _make_api_call(api_call_builder.call(page), headers, projects)
          break if outcome.nil?
        end

        projects.flatten.compact
      end

      def _make_api_call(uri, headers, output)
        r = http_request(:get, uri, nil, headers)

        return if _api_request_limit_exhausted?(r)

        parsed_response = _parse_json_response(r.body)
        return if parsed_response.nil? || parsed_response.empty?

        sleep(2) # sleep to avoid triggering rate limiting
        output << parsed_response&.map { |j| j['web_url'] } # in case any random response returned; use safe nil nav
      end

      def return_uri_builder(info)
        if _get_entity_type_string == 'GitlabCredential'
          ->(x) { "#{info.host}/api/v4/projects?page=#{x}&simple=true&owned=true&per_page=100" }
        elsif _get_entity_type_string == 'GitlabAccount'
          group = is_gitlab_group?(info.host, info.account, info.token)
          if group
           ->(x) { "#{info.host}/api/v4/group/#{info.account}/projects?page=#{x}&simple=true&per_page=100" }
          else
            ->(x) { "#{info.host}/api/v4/users/#{info.account}/projects?page=#{x}&simple=true&per_page=100" }
          end
        end
      end

      def parse_entity_information(entity_type)
        if entity_type == 'GitlabCredential'
          _parse_gitlab_credential_entity
        elsif entity_type == 'GitlabAccount'
          _parse_gitlab_account_entity
        end
      end

      def _parse_gitlab_credential_entity
        host = _get_entity_sensitive_detail('gitlab_host')
        access_token = retrieve_gitlab_token(host, 'GitlabCredential')

        if access_token.nil?
          _log_error 'Valid access token required when using GitlabCredential entity.'
          return
        end

        Struct.new(:host, :token).new(host, access_token)
      end

      def _parse_gitlab_account_entity
        parsed_uri = parse_gitlab_uri(_get_entity_name, 'account')
        parsed_uri.account.gsub!('/', '%2f') # urlencode / if its a project name

        if [parsed_uri.host, parsed_uri.account].include?(nil)
          _log_error 'Error parsing Gitlab Account; ensure the format is \'https://gitlab.intrigue.io/username\''
          return
        end

        parsed_uri.token = retrieve_gitlab_token(parsed_uri.host, 'GitlabAccount') || ''

        parsed_uri
      end

      def _return_total_requests(uri, headers)
        r = http_request(:get, uri.call(1), nil, headers)
        return unless _first_request_checklist(r)

        r.headers.fetch('x-total-pages')&.to_i
      end

      def _first_request_checklist(request)
        outcome = true

        case request.code
        when '404'
          _log_error 'User/Project does not exist; aborting.'
          outcome = false
        when '401'
          _log_error 'Lack of authorization; aborting.'
          outcome = false
        end

        outcome
      end

      def _api_request_limit_exhausted?(response)
        exhausted = response.headers['RateLimit-Remaining']&.eql?('0')
        _log_error 'Request limited exhausted; aborting task.' if exhausted

        exhausted
      end

      def _parse_json_response(response)
        JSON.parse(response)
      rescue JSON::ParserError
        _log_error 'Unable to parse JSON'
      end
    end
  end
end
