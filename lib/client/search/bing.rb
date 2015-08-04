require 'json'
require 'open-uri'
require 'net/http'

module Client
module Search
module Bing

  class SearchScraper

    include Task::Web

    def search(search_string,pages=5)
      first_item = 1
      responses = []

      pages.times do |x|
        uri = "http://www.bing.com/search?q=#{search_string}&first=#{first_item}"
        responses << http_get_body(uri)

        # Iterate through results
        first_item += 10
      end
    responses
    end

  end

  ###
  ### Code based on the 'searchbing' gem by @rcullito:
  ###    https://github.com/rcullito/searchbing
  ###


  # The Bing Class provides the ability to connect to the bing search api hosted on the windows azure marketplace.
  # Before proceeding you will need an account key, which can be obtained by registering an accout at http://windows.microsoft.com/en-US/windows-live/sign-in-what-is-microsoft-account
  class SearchService


    # Create a new object of the bing class
    #   >> bing_image = Bing.new('your_account_key_goes_here', 10, 'Image', {:Adult => 'Strict'})
    #   => #<Bing:0x9d9b9f4 @account_key="your_account_key", @num_results=10, @type="Image", @params={:Adult => 'Strict'}>
    # Arguments:
    #   account_key: (String)
    #   num_results: (Integer)
    #   type: 	   (String)
    #   params: 	   (Hash)

      def initialize(account_key, num_results, type, params = {})

        @account_key = account_key
        @num_results = num_results
        @type = type
        @params = params
      end

      attr_accessor :account_key, :num_results, :type, :params

      # Search for a term, the result is an array of hashes with the result data
      #   >> bing_image.search("puffin", 25)
      #   => [{"__metadata"=>{"uri"=>"https://api.datamarket.azure.com/Data.ashx/Bing/Search/Image?Query='puffin'&$skip=25&$top=1", "type"=>"Image
      # Arguments:
      #   search_term: (String)
      #   offset: (Integer)

      def search(search_term, offset = 0)

        user = ''
        web_search_url = "https://api.datamarket.azure.com/Bing/Search/v1/Composite?Sources="
        sources_portion = URI.encode_www_form_component('\'' + @type + '\'')
        query_string = '&$format=json&Query='
        query_portion = URI.encode_www_form_component('\'' + search_term + '\'')
        params = "&$top=#{@num_results}&$skip=#{offset}"
        @params.each do |k,v|
          params << "&#{k.to_s}=\'#{v.to_s}\'"
        end

        full_address = web_search_url + sources_portion + query_string + query_portion + params

        uri = URI(full_address)
        req = Net::HTTP::Get.new(uri.request_uri)
        req.basic_auth user, account_key

        res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https'){|http|
          http.request(req)
        }
        
        body = JSON.parse(res.body, :symbolize_names => true)
        result_set = body[:d][:results]
      end
    end

end
end
end
