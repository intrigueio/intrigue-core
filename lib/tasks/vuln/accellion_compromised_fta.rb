module Intrigue
    module Task
    class AccellionCompromisedFta < BaseTask

      def self.metadata
        {
          :name => "vuln/accellion_compromised_fta",
          :pretty_name => "Vuln Check - Accellion compromised secure file transfer appliance",
          :identifiers => [],
          :authors => ["shpendk"],
          :description => "Accellion check for compromised secure file transfer appliance",
          :references => [
            "https://www.itnews.com.au/news/accellion-hack-behind-reserve-bank-of-nz-data-breach-559642"
          ],
          :type => "vuln_check",
          :passive => false,
          :allowed_types => ["Uri"],
          :example_entities => [ {"type" => "Uri", "details" => {"name" => "https://intrigue.io"}} ],
          :allowed_options => [  ],
          :created_types => []
        }
      end

      def run
        super

        compromised_endpoints = [
            "courier/about.html",
            "courier/oauth.api",
            "log/adminpl.log"
        ]

        uri = URI(_get_entity_name)

        # request them
        is_vulnerable = false
        res = nil
        _log "Testing compromised endpoints"
        compromised_endpoints.each do |e|
            response = http_request :get, "#{uri.scheme}://#{uri.hostname}:#{uri.port}/#{e}"
            if response.response_code == 200
                is_vulnerable = true
                res = response
            end
        end
        
        if is_vulnerable
            _log "Vulnerable!"
            _create_linked_issue("accellion_compromised_fta", {
              proof: {
                response: res.body_utf8
              }
            })
            return
        end
      end

    end
    end
    end