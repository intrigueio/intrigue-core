module Intrigue
    module Task
    class ApacheNifiMisconfiguration < BaseTask

      def self.metadata
        {
          :name => "vuln/apache_nifi_misconfiguration",
          :pretty_name => "Vuln Check - Apache NiFi Misconfiguration",
          :identifiers => [],
          :authors => ["shpendk", "F-Secure labs"],
          :description => "Apache NiFi Misconfiguration",
          :references => [
            "https://labs.f-secure.com/tools/metasploit-modules-for-rce-in-apache-nifi-and-kong-api-gateway/"
          ],
          :type => "vuln_check",
          :passive => false,
          :allowed_types => ["Uri"],
          :example_entities => [ {"type" => "Uri", "details" => {"name" => "https://intrigue.io"}} ],
          :allowed_options => [  ],
          :created_types => []
        }
      end

      def is_vuln(response)
        # parse json. If no json is found in response, automatically not vulnerable
        begin
            response_json = JSON.parse(response)
        rescue JSON::ParserError
            return false
        end

        # check if the right data is in response
        vulnerable = false
        if  response_json &&
            response_json["id"] != "" &&
            response_json["permissions"]["canWrite"] == true

            vulnerable = true
        end
        vulnerable
      end 

      def run
        super

        require_enrichment
        uri = _get_entity_name

        # request 1
        _log "Testing given url for misconfiguration"
        response = http_get_body uri
        if  is_vuln(response)
            _log "Vulnerable!"
            _create_linked_issue("apache_nifi_misconfiguration", {
              proof: {
                response: JSON.parse(response)
              }
            })
            return
        end

        # if original URI didn't work, lets try the default url
        _log "Testing misconfiguration at /nifi-api/process-groups/root"
        uri_obj = URI(uri)
        endpoint = "#{uri_obj.scheme}://#{uri_obj.hostname}:#{uri_obj.port}/nifi-api/process-groups/root"
        response = http_get_body endpoint
        if  is_vuln(response)
            _log "Vulnerable!"
            _create_linked_issue("apache_nifi_misconfiguration", {
              proof: {
                response: JSON.parse(response)
              }
            })
            return
        end
      end
    end
    end
    end

