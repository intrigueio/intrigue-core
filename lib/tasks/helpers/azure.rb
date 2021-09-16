module Intrigue
  module Task
    module Azure

      def _request_azure_oauth_token(tenant_id)
        r = http_get_body("https://future_api/get_token/#{tenant_id}")
        parsed = _parse_json_response(r)

        if parsed.nil? || parsed['access_token'].nil?
          _log_error 'Unable to retrieve Azure Access Token; aborting.'
          return nil
        end

        parsed['access_token']
      end

      def _parse_json_response(response)
        JSON.parse(response)
      rescue JSON::ParserError
        _log_error 'Issue parsing JSON.'
      end

    end
  end
end
