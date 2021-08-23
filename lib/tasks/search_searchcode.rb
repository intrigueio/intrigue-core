module Intrigue
  module Task
    class SearchSearchcode < BaseTask
      def self.metadata
        {
          name: 'search_searchcode',
          pretty_name: 'Search Searchcode',
          authors: ['maxim'],
          description: 'This task utilizes the Searchcode API to find any keywords in public repositories.',
          references: ['https://searchcode.com/api/'],
          type: 'discovery',
          passive: true,
          allowed_types: ['UniqueKeyword', 'String'],
          example_entities: [
            { 'type' => 'UniqueKeyword', 'details' => { 'name' => 'uniquevalue1337' } }
          ],
          allowed_options: [],
          created_types: ['GitlabAccount', 'GithubAccount']
        }
      end

      ## Default method, subclasses must override this
      def run
        super
        results = search_searchcode(_get_entity_name)
        repos = results.map { |r| r['repo'] }

        _log "Obtained #{repos.uniq.size} results."
        return if repos.empty?

        repos.uniq.each { |r| _create_entity('GitlabProject', { 'name' => r }) }
      end

      def search_searchcode(keyword)
        api_key = retrieve_searchcode_api_key # unused for now; come back to this later when the request structure for API is known
        pages_count = make_api_call("https://searchcode.com/api/codesearch_I/?q=#{keyword}&src=13") # 13 = gitlab
        return if pages_count.nil?

        # max 49 pages
        total_pages = pages_count['total'] > 10 ? 10 : results['total']
        api_uris = (0...total_pages).map { |t| "https://searchcode.com/api/codesearch_I/?q=#{keyword}&src=13&p=#{t}&per_page=100" }
        request_dispatcher(api_uris)
      end

      def request_dispatcher(input)
        output = []
        workers = (0...20).map do
          results = threaded_requests(input, output)
          [results]
        end
        workers.flatten.map(&:join)

        output.flatten
      end

      def threaded_requests(input_q, output_q)
        t = Thread.new do
          until input_q.empty?
            while api_uri = input_q.shift
              results = make_api_call(api_uri)
              next if results.nil?

              output_q << results['results']
            end
          end
        end
        t
      end

      def make_api_call(uri)
        response = http_get_body(uri)
        JSON.parse(response) # if nothing is parsed it returns an empty array
      rescue JSON::ParserError
        log_error 'Unable to parse JSON response.'
      end

      def retrieve_searchcode_api_key
        _get_task_config('searchcode_api_key')
      rescue MissingTaskConfigurationError
        _log 'Searchcode API key not set in task_config'
        _log 'This will limit the findings to max 100 results.'
      end
    end
  end
end
