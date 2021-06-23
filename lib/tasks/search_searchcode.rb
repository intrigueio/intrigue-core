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
        pages = return_amount_of_pages(keyword)
        return if pages.nil?

        _log_good "There are #{pages + 1} pages matching." # debug
        pages = pages > 50 ? 49 : pages  # api only allows 49 pages max; if greater than 50 default to 49
        results = threaded_lookups(keyword, pages)

        _log "Obtained #{results.size} results."
      end

      def return_amount_of_pages(query)
        response = http_get_body("https://searchcode.com/api/codesearch_I?q=#{query}")
        output = JSON.parse(response)
        total = output['total']
        return if total.nil?

        # take total and divide by 100 as 100 results per page & round up
        (total / 100.to_f).ceil
      rescue JSON::ParserError
        _log_error 'Error Parsing JSON'
      end

      def threaded_lookups(query, pages)
        input =  0.step(pages).map { |p| "https://searchcode.com/api/codesearch_I?q=#{query}&p=#{p}&per_page=100" }
        output = []

        workers = (0...20).map do
          search = search_page(input, output)
          [search]
        end
        workers.flatten.map(&:join)
        output
      end

      def search_page(input_q, output_q)
        t = Thread.new do
          until input_q.empty?
            while url = input_q.shift
              begin
                _log "Attempting #{url}" # debug
                response = http_get_body url
                results_json = JSON.parse(response)
              rescue JSON::ParserError
                next
              end
              output_q << results_json['results']
            end
          end
        end
        t
      end

    end
  end
end
