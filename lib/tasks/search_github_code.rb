module Intrigue
  module Task
    class SearchGithubCode < BaseTask
      def self.metadata
        {
          name: 'search_github_code',
          pretty_name: 'Search Github Code',
          authors: ['maxim'],
          description: 'balbalablabala',
          references: ['000000'],
          type: 'discovery',
          passive: false,
          allowed_types: ['String'],
          example_entities: [{ 'type' => 'String', 'details' => { 'name' => '__IGNORE__', 'default' => '__IGNORE__' } }], # what if we have multiple keywords? lets ignore this for now
          allowed_options: [
            { name: 'keywords', regex: 'alpha_numeric_list', default: '' },
          ], # use authentication?
          created_types: ['GithubRepository']
        }
      end

      ## Default method, subclasses must override this
      def run
        super

        gh_client = initialize_gh_client
        gh_client.auto_paginate = true

        keywords = _get_option('keywords').delete(' ').split(',')
        all_results = keywords.map { |keyword| authenticated_call(gh_client, keyword) }
        all_results.flatten!

        p all_results
      end


      def authenticated_call(client, key)
        results = client.search_code(key, { 'per_page': 100 })['items']
        results.map { |r| r['html_url'] } unless results.nil? || results.empty?
      end


    end
  end
end
