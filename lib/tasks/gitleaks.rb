module Intrigue
  module Task
    class Gitleaks < BaseTask
      def self.metadata
        {
          name: 'gitleaks',
          pretty_name: 'Gitleaks',
          authors: ['maxim', 'Anas Ben Salah', 'zricethezav'],
          description: 'Gitleaks is a SAST tool for detecting hardcoded secrets like passwords, api keys, and tokens in git repos.',
          references: ['https://github.com/zricethezav/gitleaks#readme'],
          type: 'discovery',
          passive: false,
          allowed_types: ['URI', 'GithubRepository'],
          example_entities: [{ 'type' => 'URI', 'details' => { 'name' => 'https://github.com/my-insecure/repo' } }],
          allowed_options: [
            { name: 'use_authentication', regex: 'boolean', default: true },
            { name: 'custom_keywords', regex: 'alpha_numeric_list', default: '' }
          ],
          created_types: []
        }
      end

      ## Default method, subclasses must override this
      def run
        super

        repo_uri = _get_entity_name
        custom_keywords = _get_option('custom_keywords').delete(' ').split(',')
        custom_config = create_gitleaks_custom_config(custom_keywords) unless custom_keywords.empty?

        access_token = retrieve_gh_access_token if _get_option('use_authentication')

        issues = run_gitleaks(repo_uri, access_token, custom_config)
        return if issues.nil?

        _log_good "Found #{issues.size} suspicious commits."
        issues.each {|i| create_suspicious_commit_issue(i) } 

      end

      def retrieve_gh_access_token
        client = initialize_gh_client
        _get_task_config('github_access_token') if client
        # return access key since github client is valid meaning api key works
      end
    end
  end
end
