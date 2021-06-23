module Intrigue
  module Task
    class SearchGrepApp < BaseTask
      def self.metadata
        {
          name: 'search_grep_app',
          pretty_name: 'Search Grep.app',
          authors: ['m-q-t', 'hello@grep.app'],
          description: 'Uses the grep.app API to search for code containing unique keywords.',
          references: ['https://grep.app'],
          type: 'discovery',
          passive: true,
          allowed_types: ['String', 'UniqueKeyword'],
          example_entities: [{ 'type' => 'String', 'details' => { 'name' => 'unique keyword' } }],
          allowed_options: [], # max results total
          created_types: []
        }
      end

      def run
        super

        query = _get_entity_name
        results = search(query)

        _log "Obtained #{results.size} results."
      end

      def search(q)
        repo_urls = []
        # max pages 100
        begin
          page = 0
          _log "Parsing page #{page}"
          while page <= 100 # max 49 pages
            response = http_get_body "https://grep.app/api/search?q=#{q}&page=#{page}"
            output = JSON.parse(response)
            results = output['hits']

            break if results['total'].zero?

            results['hits'].each do |r|
              repo_urls << r['id']['raw']
            end

            page += 1
          end
        rescue JSON::ParserError
          _log_error 'Error parsing JSON.'
        end

        repo_urls
      end

    end
  end
end
