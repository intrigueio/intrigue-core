module Intrigue
    module Task
    class KongExposedAdminInterface < BaseTask
  
      def self.metadata
        {
          :name => "vuln/kong_exposed_admin_interface",
          :pretty_name => "Vuln Check - Kong Exposed Admin Interface",
          :identifiers => [],
          :authors => ["shpendk", "F-Secure labs"],
          :description => "Kong Exposed Admin Interface",
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
            response_json["tagline"] == "Welcome to kong" && # tagline confirms exposed admin API
              ( response_json["configuration"]["loaded_plugins"]["pre-function"] == true || # one of these plugins needed for RCE
                response_json["configuration"]["loaded_plugins"]["post-function"] == true )
            vulnerable = true
        end
        vulnerable
      end 

      def run
        super
  
        #require_enrichment
        uri = _get_entity_name
  
        # request 1
        _log "Testing entity for exposed admin interface"
        response = http_get_body uri
        if is_vuln(response)
          _log "Vulnerable!"
          _create_linked_issue("kong_exposed_admin_interface", {
            proof: {
              response: JSON.parse(response)
            }
          })
          return
        end
  
        # if original URI didn't work, lets try the default port 8001
        _log "Testing entity at port 8001 for exposed admin interface"
        uri_obj = URI(uri)
        endpoint = "#{uri_obj.scheme}://#{uri_obj.hostname}:8001"
        response = http_get_body endpoint
        if  is_vuln(response)
          _log "Vulnerable!"
          _create_linked_issue("kong_exposed_admin_interface", {
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
  