require 'json'
require 'open-uri'
require 'net/http'

module Client
module Search
module Bing

  class SearchService

    include Intrigue::Task::Web

    def initialize(api_key)
      @api_key = api_key
    end

    def search(search_string)

      uri = "https://api.cognitive.microsoft.com/bing/v7.0/search?q=#{URI.escape(search_string)}"
      json_response = http_request(:get, uri, {"Ocp-Apim-Subscription-Key" => "#{@api_key}" })

      parsed_response = JSON.parse(json_response.body)

    parsed_response
    end

  end


end
end
end
