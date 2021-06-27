module Intrigue
  module Task
    module Serp
      def search_serp(params)
        begin
          search = GoogleSearch.new(params)
          hash = search.get_hash
          result = JSON.parse(hash.to_json)
        rescue JSON::ParserError => e
          _log_error "Unable to parse JSON: #{e}"
        end
        result
      end
    end
  end
end
