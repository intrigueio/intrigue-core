require 'shodan'

module Client
  module Search
    module Shodan
      class ApiClient
        include Intrigue::Task::Web

        attr_accessor :service_name

        def initialize(key)
          @service_name = "shodan"
          @api =::Shodan::Shodan.new(key)
        end

        def search(search_string)
          begin
            response = @api.search(search_string)
          rescue Timeout::Error => e
            response = nil
          rescue JSON::ParserError => e
            # Unable to parse, likely we have the wrong key. return false.
            response = nil
          end
          response
        end
      end
    end
    end
end
