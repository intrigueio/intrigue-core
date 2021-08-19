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
          allowed_types: ['GitlabAccount'],
          example_entities: [{ 'type' => 'GitlabAccount', 'details' => { 'name' => 'intrigueio' } }],
          allowed_options: [
            { name: 'gitlab_instance_uri', regex: 'alpha_numeric_list', default: 'https://gitlab.com' }
          ],
          created_types: ['GitlabProject']
        }
      end

      # ADD RATE LIMIT CHECK

      ## Default method, subclasses must override this
      def run
        super
        parsed_uri = parse_gitlab_uri(_get_entity_name)
        host = parsed_uri['host']
        account_name = parsed_uri['account']
        account_name.gsub!('/', '%2f') # in case this is a subgroup ensure to urlencode any /

        if [host, account_name].include?(nil)
          _log_error 'Error parsing Gitlab Account; ensure the format is \'https://gitlab-instance.com/username\''
          return
        end

        results = retrieve_repositories(account_name, host)
        return if results.nil?

        _log "#{account_name} has no projects" if results.empty?
        return if results.empty?

        _log_good "Obtained #{results.size} projects belonging to #{account_name.gsub('%2f', '/')}."

        results.each { |r| create_gitlab_project_entity("#{host}/#{r}") }
      end

      def retrieve_repositories(name, host)
        # if token is nil ; set to empty since gitlab will ignore empty value in private-token header
        access_token = retrieve_gitlab_token || ''
        headers = { 'PRIVATE-TOKEN' => access_token } if access_token

        uri = if group?(name, access_token)
                "#{host}/api/v4/groups/#{name}/projects"
              else
                "#{host}/api/v4/users/#{name}/projects"
              end

        total_pages = http_request(:get, "#{uri}?per_page=100", nil, headers).headers['x-total-pages']

        if total_pages.nil?
          _log "No account or group with the name #{name} exists."
          return nil
        end

        results = (1..total_pages.to_i).map do |p|
          _log "Obtaining results for Page #{p}."
          json_result = http_get_body("#{uri}?page=#{p}&per_page=100", nil, headers)
          parse_results(json_result)
        end

        results.flatten
      end

      def parse_results(json_blob)
        begin
          parsed_json = JSON.parse(json_blob)
        rescue JSON::ParserError
          _log_error 'Unable to parse JSON'
          return nil
        end

        repositories = parsed_json.map { |item| item['path_with_namespace'] }
        repositories
      end

      def create_gitlab_project_entity(project_uri)
        parsed_project_uri = parse_gitlab_uri(project_uri)
        _create_entity 'GitlabProject', {
          'name' => project_uri,
          'project_name' => parsed_project_uri['project'],
          'project_uri' => project_uri,
          'project_account' => parsed_project_uri['account']
        }
      end
    end
  end
end
