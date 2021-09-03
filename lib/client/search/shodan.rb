module Intrigue
module Client
  module Search
    module Shodan
      class ApiClient
        include Intrigue::Task::Web

        attr_accessor :service_name

        def initialize(key)
          @service_name = "shodan"
          @api_key = key
        end

        def search_ip(string)
          begin
            response = JSON.parse(http_get_body("https://api.shodan.io/shodan/host/#{string}?key=#{@api_key}"))
          rescue Timeout::Error => e
            response = nil
          rescue JSON::ParserError => e
            # Unable to parse, likely we have the wrong key. return false.
            response = nil
          end
          response
        end

        def search_netblock(string)
          full_json_response = []

          req_uri = -> (page) { "https://api.shodan.io/shodan/host/search?key=#{@api_key}&query=net:#{string}&page=#{page}" }
          response = _shodan_pagination(req_uri.call(1))

          return if response.nil?
          return if response['total'].zero?

          full_json_response << response['matches'] # concat matches into array
          total_pages = (response['total'].to_i / 100.to_f).ceil # get amount of total pages rounded up

          return { 'data' => full_json_response.flatten } if total_pages == 1 # only one page < 100 results; return 

          (2..total_pages).each do |i|
            response = _shodan_pagination(req_uri.call(i))
            next if response.nil?

            full_json_response << response['matches']
            sleep(1) # do not upset Shodan
          end

          { 'data' => full_json_response.flatten }
        end

        def _shodan_pagination(request)
          JSON.parse(Typhoeus.get(request).body)
        rescue Timeout::Error, JSON::ParserError
          _log_error 'Unable to parse JSON response for Shodan API request'
        end

        ### search an IP if it is a honeypot or a real control system.
        def search_honeypot_ip(string)
          begin
            response = http_get_body("https://api.shodan.io/labs/honeyscore/#{string}?key=#{@api_key}")
          rescue Timeout::Error => e
            response = nil
          end
          response
        end
        
      end
    end
    end
end
end
