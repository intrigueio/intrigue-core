module Intrigue
  module Task
    module Gitlab

      def retrieve_gitlab_token
      begin
        token = _get_task_config('gitlab_access_token')
      rescue MissingTaskConfigurationError
        _log 'Gitlab Access Token is not set in task_config.'
        _log 'Please not this means private repositories will not be retrieved.'
        return nil
      end

      token if gitlab_token_valid?(token)
      end

      def gitlab_token_valid?(token)
        headers = { 'PRIVATE-TOKEN' => token }
        r = http_request(:get, 'https://gitlab.com/api/v4/groups/invalid', nil, headers)

        r.code != '401' # as long as response is not 401 token is valid
      end

      def is_group?(name, token)
        headers = { 'PRIVATE-TOKEN' => token } 
        r = http_request(:get, "https://gitlab.com/api/v4/groups/#{name}", nil, headers)

        r.code == '200'

      end

      


    end
  end
end