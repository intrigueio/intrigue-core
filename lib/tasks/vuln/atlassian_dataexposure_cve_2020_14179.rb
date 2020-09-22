module Intrigue
    module Task
    class AtlassianCve202014179 < BaseTask
    
      def self.metadata
        {
          :name => "vuln/atlassian_dataexposure_cve_2020_14179",
          :pretty_name => "Vuln Check - Atlassian Sensitive Data Exposure CVE-2020-14179",
          :authors => ["shpendk","jcran"],
          :identifiers => [{ "cve" =>  "CVE-2020-14179" }],
          :description => "This task performs a vulnerability check for CVE-2020-14179",
          :references => ["https://github.com/projectdiscovery/nuclei-templates/pull/487"],
          :type => "vuln_check",
          :passive => false,
          :allowed_types => ["Uri"],
          :example_entities => [{"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}],
          :created_types => []
        }
      end
    
      ## Default method, subclasses must override this
      def run
        super
    
        #require_enrichment
    
        # make the request
        path = "/secure/QueryComponent!Default.jspa"
        uri = _get_entity_name
        response = http_request :get, "#{uri}#{path}"

        # fail if no response
        unless response && response.body_utf8 
            _log "No response! Failing"
            return
        end        
        
    
        # check response code and content
        if response.code.to_i == 200
            if response.body_utf8 =~ /searchers/
                _log "Vulnerable!"
                # file issue
                _create_linked_issue("atlassian_dataexposure_cve_2020_14179", { 
                  status: "confirmed",
                  proof: response.body_utf8 })
            end
        end
    end
    
    end
    end
    end
    