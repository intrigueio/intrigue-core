module Intrigue
  module Task
    module Github

      def initialize_gh_client
        begin
          access_token = _get_task_config('github_access_token')
        rescue MissingTaskConfigurationError
          _log 'Github Access Token is not set in task_config.'
          _log 'Please note this severely limits the results due to rate limiting.'
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