module Intrigue
  module Task
    module Gitlab
      def retrieve_gitlab_token
        begin
          token = _get_task_config('gitlab_access_token')
        rescue MissingTaskConfigurationError
          _log 'Gitlab Access Token is not set in task_config.'
          _log 'Please not this means private repositories or private groups will not be retrieved.'
          return nil
        end

        token if _gitlab_token_valid?(token)
      end

      def group?(name, token)
        headers = { 'PRIVATE-TOKEN' => token }
        r = http_request(:get, "https://gitlab.com/api/v4/groups/#{name}", nil, headers)

        r.code == '200'
      end

      def parse_gitlab_uri(gitlab_instance)
        # same regex as account name however project name can start with a dot or underscore but not a dash
        # gitlab groups support support subgroups
        # gitlab account names are 1-255 characters and contain dots, underscores and dashes but cannot start with them

        parsed_uri = URI(gitlab_instance)
        host = "#{parsed_uri.scheme}://#{parsed_uri.host}"
        account = gitlab_instance.scan(/#{host}\/([\d\w\-\.]{1,255}+)/i).flatten.first
        project = gitlab_instance.scan(/#{host}\/#{account}\/([\d\w\-\.]{1,255}+)/i).flatten.first
        {'host' => host, 'account' => account, 'project' => project}
      end

      private

      def _gitlab_token_valid?(token)
        headers = { 'PRIVATE-TOKEN' => token }
        r = http_request(:get, 'https://gitlab.com/api/v4/groups/invalid/donotreturn/true', nil, headers)

        _log 'Gitlab Access Token is invalid; defaulting to unauthenticated.' if r.code == '401'
        _log 'Gitlab Access Token lacks permissions; defaulting to authenticated.' if r.code == '403'

        r.code == '404'
      end
    end
  end
end
