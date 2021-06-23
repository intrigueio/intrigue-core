module Intrigue
  module Task
    class SearchSearchCode < BaseTask
      def self.metadata
        {
          name: 'search_searchcode',
          pretty_name: 'Search Searchcode',
          authors: ['m-q-t', 'ben@boyter.org'],
          description: 'Uses the searchcode API to search for code containing unique keywords across several code sources.',
          references: ['https://searchcode.com'],
          type: 'discovery',
          passive: true,
          allowed_types: ['String', 'UniqueKeyword'],
          example_entities: [{ 'type' => 'String', 'details' => { 'name' => 'unique keyword' } }],
          allowed_options: [],
          created_types: []
        }
      end

      def run
        super

        keyword = _get_entity_name
        results = search(keyword)

        _log "Obtained #{results.size} results."
      end

      def search(key)
        found_results = []

        begin
          page = 0
          while page <= 49 # max 49 pages
            response = http_get_body "https://searchcode.com/api/codesearch_I/?q=#{key}&p=#{page}"
            output = JSON.parse(response)
            results = output['results']

            break if results.nil?

            results.each do |r|
              found_results << [r['repo'], r['lines'], r['filename']]
            end

            page += 1
          end
        rescue JSON::ParserError
          _log_error 'Error parsing JSON.'
        end

        found_results
      end

    end
  end
end
