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

      ### search an IP if it is a honeypot or a real control system
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
